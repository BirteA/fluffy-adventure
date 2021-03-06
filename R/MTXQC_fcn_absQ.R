####### MTXQC functions - Absolute Quantification ######

check_mqt_batchids <- function(df_annotation, dir = path_setup) {
  #'Check matching ManualQuantTable.tsv files and annotation file
  #'
  #'
  #'
  #'
  
  
  #Create batch_id vector
  batch_id_def = create_batchid(df_annotation)
  
  #count and check number of required MQT raw tables
  nb_id = length(batch_id_def)
  file_names <- dir(paste0(dir, "input/quant/"), pattern = ".tsv") 
  
  #stop if no files detectable
  if (length(file_names) == 0) {
    message("FATAL ERROR: No tsv-files detected! Please check the folder: input/quant/")
    knitr::knit_exit()
  } else {
    message("In folder input/quant: .tsv-files detected!")
  }
  
  #stop if missing renaming of tsv-file
  #temp = grepl("ManualQ", file_names)
  
  temp = "ManualQuantTable.tsv" %in% file_names
  
  if (temp == TRUE) {
    message("FATAL ERROR: Please rename your ManualQuantTable.tsv files with Batch-Id!")
    knitr::knit_exit()
  } else {
    message("CHECKED: All ManualQuantTable.tsv-files renamed!")
  }
  
  #check number of defined batch-ids in input/quant and annotation file
  if (length(batch_id_def) < length(file_names)) {
    message("WARNING: Please check your annotation file!") 
    message("WARNING: Less files defined than you copied in the MTXQC project!")
  }
  
  if (length(batch_id_def) > length(file_names)) {
    message("WARNING: Please check the number of ManualQuantTables.tsv in your MTXQC project.")
    message("WARNING: More batches defined in your annotation file, than tsv-files present.")
  } else {
    message("Correct matching of ManualQuantTable files and annotation file content!")
  }
  
  return(batch_id_def)
}


qcurve_top5_rsquare = function(df, path){
  #'Determination of calibration curves based on the
  #'ManualQuantTable. 
  #'Two versions are currently implemented:
  #'  (1) - considering different Batch_Ids (diff_set == "yes")
  #'  (2) - data only one setup (else option)
  #'

    #here we get the r-squared for each linear regression curve
    df = ddply(df, c("Metabolite_short", "Batch_Id", "Origin"), 
               transform, adj_r_squared = summary(lm(Concentration ~ ChromIntensities))$adj.r.squared)
    
    #here we get the y-intercept for each linear regression curve
    df = ddply(df, c("Metabolite_short", "Batch_Id", "Origin"), 
               transform, intercept = coefficients(lm(Concentration ~ ChromIntensities))[1])
    
    #here we get the slope for each linear regression curve
    df = ddply(df, c("Metabolite_short", "Batch_Id", "Origin"), 
               transform, slope = coefficients(lm(Concentration ~ ChromIntensities))[2])
    
    #max and min value
    df = ddply(df, c("Metabolite_short", "Batch_Id", "Origin"), 
               transform, max = max(Concentration), min = min(Concentration))
    
    #let's write these data into a file
    write.table(df, file = paste0(path, "output/quant/top5_QMQcurveInfo.csv"), row.names = F)
    message('top5_QMQcurveInfo.csv generated!')

}

islinear_nacalc = function(met, test, cc){
  #'This functions checks if the determined peak area
  #'is within, below or above the linear range of
  #'the calibration curve
  #'Functions specifies "NaCal" if no calibration curve
  #'is available
  #'If there isn't any value for absconc it reports "na"
  #'
  
  if (cc == 'yes_cal') {
    if (!all(is.na(test))) {
      met.ch = as.character(met)
      
      curmin = min(qt$ChromIntensities[qt$Metabolite == met.ch], na.rm = T)
      curmax = max(qt$ChromIntensities[qt$Metabolite == met.ch], na.rm = T)
      answer = ifelse((test >= curmin & test <= curmax), 'linear', ifelse(test < curmin, 'below','above'))
    } else {
      answer = 'na'
    }
  } else {
    answer = 'NaCal'
  }
}

absconc = function(met, area){
  #'Absolute quantification based on calibration curves
  #'equation: y = absconc = intercept + (slope * area)
  #'
  
  
  if (!is.na(area)) {
    intercept = qt$intercept[qt$Lettercode == as.character(met)][1]
    slope = qt$slope[qt$Lettercode == as.character(met)][1]
    y = intercept + (slope * area)
  } else {y = NA}
  y
}



normalisation_calc = function(d_quant, ca = 1, soa = 1){
  #' This functions performs the calculation of normalised quantities 
  #' considering the sum of Area normalisation and the cinnamic acid factor
  #' Following units are implemented: ul (blood), mg (tissue OR protein) and count (cell extracts)
  #' Output states respectively: pmol/ml, pmol/mg or pmol/1e+6 cells
  #' 
  #' 
  #' in the absence of cinnamic acid define ca = 0, instead of ca = 1
  #' no sum of area normalisation possbile soa = 0, possible soa == 1
  
  if (nrow(d_quant) == 0) {
    
    message("Empty data frame! Check column names for matching annotation (sample_extracts, data)!")
    
  } else {
    
    #without any kind of normalization
    d_quant$Conc_pmio = ifelse(d_quant$Unit == "ul", d_quant$corr_absconc * 1000 / d_quant$Extract_vol,
                               ifelse(d_quant$Unit == "mg", 
                                      d_quant$corr_absconc * 1 / d_quant$Extract_vol,
                                      d_quant$corr_absconc * 1e+6 / d_quant$Extract_vol)) 
    
    d_quant$Conc_microM = ifelse(d_quant$Unit == "ul", 
                                 d_quant$Conc_pmio * d_quant$Extract_vol * 1000 / (1000 * 1000), NA)
    
    #norm sum of all peak areas
    if (soa == 1) {
      d_quant$sumA_Conc = d_quant$corr_absconc / d_quant$area_fac
      
      d_quant$sumA_Conc_pmio = ifelse(d_quant$Unit == "ul", d_quant$sumA_Conc * 1000 / d_quant$Extract_vol, 
                                      ifelse(d_quant$Unit == "mg",
                                             d_quant$sumA_Conc * 1 / d_quant$Extract_vol, 
                                             d_quant$sumA_Conc * 1e+6 / d_quant$Extract_vol))
      
      d_quant$sumA_Conc_microM = ifelse(d_quant$Unit == "ul", 
                                        d_quant$sumA_Conc_pmio * d_quant$Extract_vol * 1000 / (1000 * 1000), NA)
      
    } else {#soa == 0
      d_quant$sumA_Conc = rep(NA, length(d_quant$Lettercode))
      d_quant$sumA_Conc_pmio = rep(NA, length(d_quant$Lettercode))
    }
    
    #norm over cinnamic acid factor
    if (ca == 1) {
      d_quant$IntStd_Conc = d_quant$corr_absconc / d_quant$IntStd_fac
      
      d_quant$IntStd_Conc_pmio = ifelse(d_quant$Unit == "ul", d_quant$IntStd_Conc * 1000 / d_quant$Extract_vol, 
                                    ifelse(d_quant$Unit == "mg",
                                           d_quant$IntStd_Conc * 1 / d_quant$Extract_vol,  
                                           d_quant$IntStd_Conc * 1e+6 / d_quant$Extract_vol))
      
      d_quant$IntStd_Conc_microM = ifelse(d_quant$Unit == "ul", 
                                      d_quant$IntStd_Conc_pmio * d_quant$Extract_vol * 1000 / (1000 * 1000), NA)
      
      
    } else {#ca == 0
      d_quant$IntStd_Conc = rep(NA, length(d_quant$Lettercode))
      d_quant$IntStd_Conc_pmio = rep(NA, length(d_quant$Lettercode))
      d_quant$IntStd_Conc_microM = rep(NA, length(d_quant$Lettercode))
    }
    
    #norm over cinnamic acid factor and sum of Area
    if (ca == 1 && soa == 1) {
      d_quant$IntStd_sumA_Conc = d_quant$IntStd_Conc / d_quant$area_fac 
      
      d_quant$IntStd_sumA_Conc_pmio = ifelse(d_quant$Unit == "ul", d_quant$IntStd_sumA_Conc * 1000 / d_quant$Extract_vol,
                                         ifelse(d_quant$Unit == "mg",
                                                d_quant$IntStd_sumA_Conc * 1 / d_quant$Extract_vol, 
                                                d_quant$IntStd_sumA_Conc * 1e+6 / d_quant$Extract_vol))
    } 
    
    #both normalisation factors missing
    if (ca != 1 && soa != 1) {
      d_quant$IntStd_sumA_Conc = rep(NA, length(d_quant$Lettercode))
      d_quant$IntStd_sumA_Conc_pmio = rep(NA, length(d_quant$Lettercode))
      
    } 
  }
  
  return(d_quant)
}


extract_addQ_annotation = function(annotation_file, phrase) {
  
  sel_q_ann = annotation_file[grepl(phrase, annotation_file$Type),]
  
  test_row = "Setup" %in% names(annotation_file)
  
  if (test_row == TRUE) {
    sel_q_ann = sel_q_ann[,c('File','Type','Setup')]
  } else {
    sel_q_ann = sel_q_ann[,c('File','Type')]
  }
  
  #Extract Dilution information
  sel_q_ann$Dilution_Step = sapply(strsplit(as.character(sel_q_ann$Type), "_"), "[", 2)
  sel_q_ann$Dilution = 1 / as.numeric(sel_q_ann$Dilution_Step)
  
  return(sel_q_ann)
}


create_manualquanttable = function(cal_dataframe, q1_values, met_translation, plot = FALSE) {
  
  #chromintensities
  cal_dataframe = cal_dataframe[,c("Batch_Id", "Metabolite", "Dilution", "ChromIntensities")]
  cal_dataframe = merge(cal_dataframe, met_translation[,c("Metabolite", "Lettercode")])
  
  #mqt_init  
  mqt_init = merge(q1_values, cal_dataframe)
  mqt_init = subset(mqt_init, mqt_init$ChromIntensities != 99)  
  
  #calculate Concentration Quant 1:1
  quant_idx = grep("Quant", colnames(mqt_init))
  mqt_init$Concentration = mqt_init[,quant_idx] * mqt_init$Dilution
  
  #export -> distinguish addQ and standardQ
  #var_quantversion = unlist(strsplit(colnames(mqt_init[q_idx]), split = "_"))[2]
  var_quantversion = unlist(strsplit(colnames(mqt_init[quant_idx]), split = "_"))[2]
  
  if (var_quantversion == 'ext') {
    #add flag-tag for quant-values origin
    mqt_init$Origin = rep("Qadd", length(mqt_init$Lettercode))
    
    write.csv(mqt_init, paste0(path_setup, set_input, "add_quant/ManualQuantTable_additionalQ.csv"), 
              row.names = F)
    
    message(paste0("ManualQuantTable for additional calibration curves has been generated. Quant1-values: ", 
                   colnames(mqt_init[quant_idx])))
  } else {
    #add flag-tag for quant-values origin
    mqt_init$Origin = rep("Qstd", length(mqt_init$Lettercode))
    
    write.csv(mqt_init, paste0(path_setup, set_input, "quant/ManualQuantTable_calc", "_", 
                               colnames(mqt_init[q_idx]),".csv"), row.names = F)
    
    message(paste0("ManualQuantTable for standard calibration curves has been generated. Quant1_", 
                   var_quantversion))
  }
  
  if (plot == TRUE) {
    for (var in unique(mqt_init$Batch_Id)) {
      #ggplot(mqt_init, aes(Concentration, ChromIntensities)) +
      print(ggplot(subset(mqt_init, mqt_init$Batch_Id == var), aes(Concentration, ChromIntensities)) +
              geom_point() +
              geom_smooth(method = "lm", se = FALSE) +
              theme_bw() +
              ggtitle(paste0("Calibration curves: ", var)) +
              facet_wrap( ~ Lettercode, scales = "free") +
              theme(strip.text = element_text(size = 8)) #,
            #axis.text.y = element_blank(),
            #axis.text.x = element_blank())
      )
    }
  }
  
  return(mqt_init)
}

quant_metric_calc_new <- function(dataframe) {
  
  df_small <- dataframe[,c('Metabolite','Lettercode',"Batch_Id", "Origin",
                           'adj_r_squared','intercept','slope')]
  
  batch_stats <- ddply(df_small, c("Lettercode", "Batch_Id", "Origin"), transform,
                       Frac_calcurve = length(adj_r_squared) / 8)
  
  #remove duplicates
  batch_stats = unique(batch_stats, by = c("Metabolite", "Origin"))
  write.csv(batch_stats, paste0(path_setup,"output/quant/top5_CalibrationInfo_unique.csv"), row.names = F)
  
  #clean-up header
  colnames(batch_stats)[grepl("adj_r_squared", colnames(batch_stats))] <- "R2"
  
  #create table for plots
  qt_plot = melt(batch_stats, id.vars = c('Metabolite','Lettercode', "Batch_Id", "Origin"), 
                 variable.name = 'Parameter', value.name =  'Par_value')
  
  qt_plot = subset(qt_plot, qt_plot$Parameter == 'R2' | 
                     qt_plot$Parameter == 'Frac_calcurve')
  
  return(qt_plot)
}

quant_metric_calc <- function(dataframe) {
  
  df_small <- dataframe[,c('Metabolite','Lettercode',"Batch_Id",
                           'adj_r_squared','intercept','slope')]
  
  batch_stats <- ddply(df_small, c("Lettercode", "Batch_Id"), transform,
                       Frac_calcurve = length(adj_r_squared) / 8)
  
  #remove duplicates
  batch_stats = unique(batch_stats, by = 'Metabolite')
  write.csv(batch_stats, paste0(path_setup,"output/quant/top5_CalibrationInfo_unique.csv"), row.names = F)
  
  #clean-up header
  colnames(batch_stats)[grepl("adj_r_squared", colnames(batch_stats))] <- "R2"
  
  #create table for plots
  qt_plot = melt(batch_stats, id.vars = c('Metabolite','Lettercode', "Batch_Id"), 
                 variable.name = 'Parameter', value.name =  'Par_value')
  
  qt_plot = subset(qt_plot, qt_plot$Parameter == 'R2' | 
                     qt_plot$Parameter == 'Frac_calcurve')
  
  return(qt_plot)
}


eval_extractionfactor <- function(params) {
  
  #quantification factor determination
  #1/3 = 500 ul of 1500 ul quant mix polar phase dried
  quant_fullvol = as.numeric(1500)
  
  qsingle_idx = as.numeric(as.character((params[which(params$Parameter == "quant_vol"), "Value"])))
  quant_fac  = qsingle_idx / quant_fullvol  
  
  #sample factor determination
  #1: no technical backups 2: split into two technical backups  
  sample_fac = as.numeric(as.character(params[which(params$Parameter == "backups"), "Value"]))
  
  #combined = extraction factor
  extr_fac = quant_fac * sample_fac
  
  message('The quantification factor for that experimental setup: ', quant_fac)
  message('The sample factor for that experimental setup: ', sample_fac)
  message('The extraction factor for that experimental setup: ', extr_fac)
  
  return(extr_fac)
}


evaluate_qt_lin <- function(dataframe) {
  
  df_calcheck = ddply(dataframe, c('Metabolite','File', 'Batch_Id', 'Origin'), transform,
                      islinear = islinear_nacalc(Metabolite, PeakArea, calc_curve))
  
  df_calcheck$islinear = factor(df_calcheck$islinear, 
                                levels  =  c('below', 'linear', 'above', 'NA', 'NaCal'))
  
  write.csv(df_calcheck, paste0(path_setup, set_output, 'quant/calcheck_linearity.csv'), row.names = FALSE)
  
  #Calculate fraction of each level across Batches
  fraction_lincheck = ddply(df_calcheck, c("Lettercode", "islinear", "Batch_Id", "Origin"), 
                            summarize, 
                            count = length(PeakArea))
  
  fraction_lincheck = ddply(fraction_lincheck, c("Lettercode", "Batch_Id", "Origin"), transform,
                            sum_lin = sum(count))
  
  fraction_lincheck$prop = fraction_lincheck$count / fraction_lincheck$sum_lin
  
  #Export list
  write.csv(fraction_lincheck, paste0(path_setup, set_output,
                                      "quant/pTop5_Calibration_Samples_lincheck.csv"), row.names = FALSE)
  
  message("Position of data points regarding calibration curves evaluated.")
  return(fraction_lincheck)
}


