#! /usr/bin/env python


import os
import datetime
import numpy
from numpy.core.numeric import NaN
from osgeo import gdal
import osr

#-------------------------Filter Thresholds-----------------------------------
thresh_f1      = 0.08 # Percent reflectance
thresh_f2      = 0.7
thresh_f3      = 300  # Kelvin
thresh_f4      = 225
thresh_f5      = 2
thresh_f6      = 2
thresh_f7      = 1
thresh_f8      = 210
desertIndex    = 0.5
coldCloud_pop  = 0.4  # Percent
coldCloud_mean = 295  # Kelvin
thermal_effect = 40.0 # Percent
snow_threshold = 1    # Percent

#-------------------------Functions/Filters-----------------------------------

# Function is only applied to masked data
def water_test(ndvi, array):
    # water = (ndvi < 0.1) or ((nir < 0.04) and (swir1 < 0.05))
    water = numpy.logical_or(ndvi < -0.1, numpy.logical_or(array[3,:,:]
                                 < 0.04, array[4,:,:] < 0.05))
    return water

# Function is only applied to masked data
# Calculate NDVI
def ndvi(array):
    # ndvi = (nir -red)/(nir + red)
    ndvi = numpy.divide((array[3,:,:] - array[2,:,:]),
                        (array[3,:,:] + array[2,:,:]))
    return ndvi

# Function is only applied to masked data
# Calculate NSDI; FILTER 2
def ndsi(array):
    # ndsi = (green - swir1)/(green + swir1)
    ndsi = numpy.divide((array[1,:,:] - array[4,:,:]),
                        (array[1,:,:] + array[4,:,:]))
    return ndsi

# Function is only applied to masked data
# Calculate band 5/6 composite; FILTER 4
def filter4(array):
    # c56 = (1 - swir1) * TM6
    c56 = (1 - array[4,:,:])*array[5,:,:]
    return c56

# Function is only applied to masked data
# Calculate band 4/3 ratio; FILTER 5/Simple Ratio
def filter5(array):
    # sr = nir/red
    sr = numpy.divide(array[3,:,:],array[2,:,:])
    return sr

# Function is only applied to masked data
# Calculate band 4/2 ratio; FILTER 6
def filter6(array):
    # f6 = nir/green
    f6 = numpy.divide(array[3,:,:],array[1,:,:])
    return f6

# Function is only applied to masked data
# Calculate band 4/5 ratio; FILTER 7
def filter7(array):
    # f6 = nir/swir1
    f7 = numpy.divide(array[3,:,:],array[4,:,:])
    return f7

# Calculate skewness. Couldn't find a numpy alternative
def skewness(array, mean, stdv, count):
    cubed_deviates = (array - mean)**3
    sum_cubed_dv   = cubed_deviates.sum()
    cubed_stdv     = stdv**3
    return (sum_cubed_dv/cubed_stdv)/count

# ACCA Second Pass
def acca_2nd_pass(cloud, ambig, therm, mean):
    
    global logfile
    logfile.write('Pass Two Engaged\n')

    cloud_stddev    = therm[cloud].std()
    cloud_count     = cloud.sum() # Sum is used as valid pixels = 1
    
    #stddev_string = ('Standard Deviation: ', cloud_stddev)
    #logfile.write(str(stddev_string) + '\n')
    logfile.write('Standard Deviation: %f' %cloud_stddev)
    
    # Histogram Percentiles for new thermal thresholds
    upper     = numpy.percentile(therm[cloud], 97.5)
    lower     = numpy.percentile(therm[cloud], 83.5)
    upper_max = numpy.percentile(therm[cloud], 98.75)
    
    #upper_string = ('97.5 %tile: ', upper)
    #lower_string = ('83.5 %tile: ', lower)
    #upmax_string = ('98.75 %tile: ', upper_max)
    #logfile.write(str(upper_string))
    #logfile.write(str(lower_string))
    #logfile.write(str(upmax_string))

    logfile.write('97.5 percentile: %f\n' %upper)
    logfile.write('83.5 percenttile: %f\n' %lower)
    logfile.write('98.75 percenttile: %f\n' %upper_max)

    

    # Test for negative skewness
    skew = skewness(therm[cloud], mean=mean, stdv=cloud_stddev, 
                    count=cloud_count)
    print 'skew', skew
    
    #skew_string = ('Skewness: ', skew)
    #logfile.write(str(skew_string) + '\n')
    logfile.write('Skewness: %f\n' %skew)

    # Calculate threshold shift
    shift = skew * cloud_stddev
    if shift > 1:
        shift = 1

    if skew > 0:
        # change the upper and lower thresholds
        new_upper = upper + shift
        new_lower = lower + shift
        if new_upper > upper_max:
            if new_lower > upper_max:
                new_lower = (upper_max - upper)
        else :
            new_upper = upper_max
    
        #query  = (therm[ambig] > new_lower) * (therm[ambig] <= new_upper)
        #query2 = therm[ambig] <= new_lower # Returns a 1 dimensional 
        query  = (therm > lower) * (therm <= upper)
        query2 = therm <= lower
    
        # Compute stats for each query/class
        # Max
        qmax  = therm[query].max()
        qmax2 = therm[query2].max()
        
        #qmx_string  = ('Class 1 max: ', qmax)
        #qmx2_string = ('Class 2 max: ', qmax2)     
        #logfile.write(str(qmx_string) + '\n')
        #logfile.write(str(qmx2_string) + '\n')
        logfile.write('Class 1 max: %f\n' %qmax)
        logfile.write('Class 1 max: %f\n' %qmax2)
         
    
        # Mean
        qmean  = therm[query].mean()
        qmean2 = therm[query2].mean()
        
        #qmn_string  = ('Class 1 mean: ', qmean)
        #qmn2_string = ('Class 2 mean: ', qmean2)        
        #logfile.write(str(qmn_string) + '\n')
        #logfile.write(str(qmn2_string) + '\n')
        logfile.write('Class 1 mean: %f\n' %qmean)
        logfile.write('Class 2 mean: %f\n' %qmean2)
    
        # Class percentage of scene
        qpop  = (float(query.sum())/ambig.size)*100
        qpop2 = (float(query2.sum())/ambig.size)*100
        
        #qpop_string  = ('Class 1 percent: ', qpop)
        #qpop2_string = ('Class 2 percent: ', qpop2)        
        #logfile.write(str(qpop_string) + '\n')
        #logfile.write(str(qpop2_string) + '\n')
        logfile.write('Class 1 percent: %f\n' %qpop)
        logfile.write('Class 2 percent: %f\n' %qpop2)
        

    
        if qpop < thermal_effect:
            if qmean < coldCloud_mean:
                # Combine all cloud classes
                return cloud + query + query2
            elif qpop2 < thermal_effect:
                if qmean2 < coldCloud_mean:
                    # Combine lower threshold clouds and pass 1 clouds
                    return cloud + query2
            else: # Keep first pass cloud
                return ""
        else: # Keep fist pass cloud
            return ""
    
    else:
        #query  = (therm[ambig] > lower) * (therm[ambig] <= upper)
        #query2 = therm[ambig] <= lower
        query  = (therm > lower) * (therm <= upper)
        query2 = therm <= lower
        
        # Debug
        print 'query', query.shape
        print 'therm', therm.shape
        print 'query2', query2.shape
        print 'ambig', ambig.shape
    
        # Compute stats for each query/class
        # Max
        qmax  = therm[query].max()
        qmax2 = therm[query2].max()
        
        #qmx_string  = ('Class 1 max: ', qmax)
        #qmx2_string = ('Class 2 max: ', qmax2)        
        #logfile.write(str(qmx_string) + '\n')
        #logfile.write(str(qmx2_string) + '\n')
        logfile.write('Class 1 max: %f\n' %qmax)
        logfile.write('Class 1 max: %f\n' %qmax2)
        
        
    
        # Mean
        qmean  = therm[query].mean()
        qmean2 = therm[query2].mean()
        
        #qmn_string  = ('Class 1 mean: ', qmean)
        #qmn2_string = ('Class 2 mean: ', qmean2)        
        #logfile.write(str(qmn_string) + '\n')
        #logfile.write(str(qmn2_string) + '\n')
        logfile.write('Class 1 mean: %f\n' %qmean)
        logfile.write('Class 2 mean: %f\n' %qmean2)
        
    
        # Class percentage of scene
        qpop  = (float(query.sum())/ambig.size)*100
        qpop2 = (float(query2.sum())/ambig.size)*100
        
        #qpop_string  = ('Class 1 percent: ', qpop)
        #qpop2_string = ('Class 2 percent: ', qpop2)        
        #logfile.write(str(qpop_string) + '\n')
        #logfile.write(str(qpop2_string) + '\n')
        logfile.write('Class 1 percent: %f\n' %qpop)
        logfile.write('Class 2 percent: %f\n' %qpop2)
        

        if qpop < thermal_effect:
            if qmean < coldCloud_mean:
                # Combine all cloud classes
                return cloud + query + query2
            elif qpop2 < thermal_effect:
                if qmean2 < coldCloud_mean:
                    # Combine lower threshold clouds and pass 1 clouds
                    return cloud + query2
            else: # Keep first pass cloud
                return ""
        else: # Keep fist pass cloud
            return ""



def acca(m_array):
    
    global logfile
    
#    iobj = gdal.Open(imgfile, gdal.gdalconst.GA_ReadOnly)
#    m_array = iobj.ReadAsArray()
    dims = m_array.shape
    
    # Create the array for Ambiguous Pixels
    ambig = numpy.zeros((dims[1],dims[2]))
    
    # Debug
    print 'ambig', ambig.shape
    
    # Keep an un-NaNed copy of the thermal band for later use
    therm = m_array[5]
    
    
    # Filter 1; brightness threshold (remove dark targets)
    query   = numpy.where(m_array[2,:,:] > thresh_f1, 1, NaN)
    m_array = m_array * query
    
    
    
    
    # Filter 2: NDSI
    query   = numpy.where(ndsi(m_array) < thresh_f2, 1, NaN)
        
    # Find the snow pixels. Sum is used to find the total cloud pixels
    # as valid pixels = 1.  Sum of ones therefore = count
    find         = numpy.where(ndsi(m_array) >= thresh_f2, 1, 0)
    snow_pixels  = find.sum() # Sum is used as valid pixels = 1
    snow_percent = (float(snow_pixels)/ambig.size) * 100
    
    m_array = m_array * query
    
    #Snow_String = ('Snow Percent: ', snow_percent)
    #logfile.write(str(Snow_String) + '\n')
    logfile.write('Snow Percent: %f\n' %snow_percent)
    
    
    # Filter 3; Temp. threshold
    query   = numpy.where(m_array[5,:,:] < thresh_f3, 1, NaN)
    m_array = m_array * query
    
    
    
    
    # Filter 4; Band 5/6 composite
    query   = numpy.where(filter4(m_array) < thresh_f4, 1, NaN)
       
    # Get ambiguous pixels
    find  = numpy.where(filter4(m_array) >= thresh_f4, 1, 0)
    ambig = ambig + find
    
    m_array = m_array * query
    
    
    
    
    # Filter 5; Band 4/3 ratio (Simple veg ratio)
    query   = numpy.where(filter5(m_array) < thresh_f5, 1, NaN)
        
    # Get ambiguous pixels
    find  = numpy.where(filter5(m_array) >= thresh_f5, 1, 0)
    ambig = ambig + find
    
    m_array = m_array * query

 

    # Filter 6; Band 4/2 ratio (Dying/senescing veg)
    query   = numpy.where(filter6(m_array) < thresh_f6, 1, NaN)
    
    # Tally filter 6 survivors
    #f6_surv = query.sum() # Sum is used as valid pixels = 1
    f6_surv = numpy.nansum(query)

    # Get ambiguous pixels
    find  = numpy.where(filter6(m_array) >= thresh_f6, 1, 0)
    ambig = ambig + find
    
    m_array = m_array * query




    # Filter 7; Band 4/5 ratio (Identify highly reflective soils/rocks)
    # The results of this query are clouds at first pass
    query = numpy.where(filter7(m_array) > thresh_f7, 1, NaN)

    # Tally filter 7 survivors
    #f7_surv      = query.sum() # Sum is used as valid pixels = 1
    f7_surv      = numpy.nansum(query)
    Desert_Index = float(f7_surv)/f6_surv
    
    #DI_String    = ('Desert Index: ', Desert_Index)
    logfile.write('Desert Index: %f\n' %Desert_Index)

    # Get ambiguous pixels
    find  = numpy.where(filter7(m_array) <= thresh_f7, 1, 0)
    ambig = (ambig + find) > 0 # Type boolean; used for indexing

    m_array = m_array * query 
    



    # Filter 8; Band 5/6 composite (Separate warm/cold clouds)
    cold_cloud    = filter4(m_array) < thresh_f8
    warm_cloud    = filter4(m_array) > thresh_f8

    cold_cloud_pop  = (float(cold_cloud.sum())/ambig.size) * 100
    cold_cloud_mean = therm[cold_cloud].mean()
    
    #cld_pop_string  = ('Cold Cloud Percent: ', cold_cloud_pop)
    #cld_mean_string = ('Cold Cloud Mean: ', cold_cloud_mean)
    #logfile.write(str(cld_pop_string) + '\n')
    #logfile.write(str(cld_mean_string) + '\n')
    logfile.write('Cold Cloud Percent: %f' %cold_cloud_pop)
    logfile.write('Cold Cloud Mean: %f' %cold_cloud_mean)

        
         
#"""
#             Tests for snow and desert.  If the thresholds aren't
#             breached, Pass two is implemented.
#"""

    # Snow test and desert test
    if Desert_Index > desertIndex and snow_percent > snow_threshold:
        ambig = (ambig + warm_cloud) > 0
        
        # Inititate 2nd Pass Testing
        r_cloud = acca_2nd_pass(cloud=cold_cloud, ambig=ambig, therm=therm, 
                                mean=cold_cloud_mean)
        if r_cloud == "":
            return (cold_cloud + warm_cloud)
        else:
            return r_cloud
    
    elif Desert_Index > desertIndex:
        cloud = (cold_cloud + warm_cloud) > 0 # To give a boolean array
        
        # Inititate 2nd Pass Testing
        r_cloud = acca_2nd_pass(cloud=cloud, ambig=ambig, therm=therm, 
                                mean=cold_cloud_mean)
        if r_cloud == "":
            return cloud
        else:
            return r_cloud
    else:
        # Do nothing cloud = cold cloud, no second processing
        return cold_cloud


#-------------------------Apply Quality Flags---------------------------------

# Need to incorporate the use of the null and sat masks
# In order to use the 'masked feature', the 0's and 1's have to be reversed
# Otherwise the good data is removed
#def reverse_qual(qflag):
#    rqflag = numpy.ma.masked_greater(qflag, 0)
#    return ~rqflag.mask

# Once the true/false has been inverted apply the null mask
# rqflag is the reversed quality flag
#def apply_null_mask(array, rqflag):
#    array = numpy.ma.array(array, mask = rqflag[8])
#    return array

#-------------------------ACCA Processing-------------------------------------

# Get the image array and quality flag array and apply masking
#rqflag = reverse_qual(qflag)
#m_array = apply_null_mask(array, rqflag)

def Main():
    
    global logfile
    
    start_time = datetime.datetime.now()
    
    logfile = open('Logfile_subs.txt', 'w')
    
    #imgfile = r'L5_2009_12_04_correct_units'
    imgfile = r'C:\WINNT\Profiles\u08087\My Documents\Imagery\2009_12_04\Other_Test_Subs\subs'
    iobj = gdal.Open(imgfile, gdal.gdalconst.GA_ReadOnly)
    m_array = iobj.ReadAsArray()
    
    logfile.write(imgfile + '\n')
    
    metadata     = iobj.GetMetadata_Dict()
    geoTransform = iobj.GetGeoTransform()
    prj          = iobj.GetProjection()
    spt_ref      = osr.SpatialReference()
    columns      = iobj.RasterXSize
    rows         = iobj.RasterYSize
    
    cloud = acca(m_array)
    
    # Get Final percent of cloud layer
    Cloud_Percent = float(cloud.sum())/cloud.size
    
    #cld_pct_string = ('Final Cloud Layer Percent: ', Cloud_Percent)
    logfile.write('Final Cloud Layer Percent: %f' %Cloud_Percent)
    
    out_fname = r'ACCA_Script_run_subs.tif'
    driver = gdal.GetDriverByName("GTiff")
    outDataset = driver.Create(out_fname, columns, rows)
    outBand = outDataset.GetRasterBand(1)
    outBand.WriteArray(cloud)
    
    outDataset.SetGeoTransform(geoTransform)
    outDataset.SetProjection(prj)
    outDataset = None
    
    end_time   = datetime.datetime.now()
    time       = end_time - start_time
    print 'Time = ', time
    
    #time_string = ('Process Time: ', time)
    logfile.write('Process Time: %s\n' %time)
    logfile.close()

if __name__ == "__main__":

    Main()










        
     



    
