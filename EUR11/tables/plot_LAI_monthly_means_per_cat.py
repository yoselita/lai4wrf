import numpy as np
import matplotlib.pyplot as plt
from numpy import arange
from scipy.optimize import curve_fit
from scipy.optimize import leastsq
from numpy import sin
import sys
import os

# Read data_versions (from arguments if given)
data_version  = sys.argv[1] if len(sys.argv) > 1 else "1.0.1"
version_extra = sys.argv[2] if len(sys.argv) > 2 else "03"

# Read LU category names
if os.path.isfile('LU_CATS.txt'):
    categories = []
    with open('LU_CATS.txt') as f:
        categories = f.readlines()
    ncats = len(categories)
else:
    print('No LU_CATS.txt file, exiting ...')
    sys.exit()


# Define x axis and labels to be months
xaxis = np.linspace(1, 12, 12)
xlabels = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']

# Load data
fmp     = np.loadtxt(f'LAI_MPTBL.csv')
fveg    = np.loadtxt(f'LAI_VEGTBL.csv')
fmean   = np.loadtxt(f'LAI_avg_v{data_version}.csv')
fstd    = np.loadtxt(f'LAI_avg_std_v{data_version}.csv')
fmax    = np.loadtxt(f'LAI_max_v{data_version}.csv')
ngrids  = np.loadtxt(f'Ngrids_per_cat.txt')

# Check and read extra version of the data if exist
if os.path.isfile(f'LAI_avg_v{version_extra}.csv'):
    fmean_extra = np.loadtxt(f'LAI_avg_v{version_extra}.csv')
    fstd_extra  = np.loadtxt(f'LAI_avg_std_v{version_extra}.csv')
    fmax_extra  = np.loadtxt(f'LAI_max_v{version_extra}.csv')
else:
    print('Extra version of data does not exist')
 
# Define 7x3 paneles in a panel-plot
fit_fixed = np.zeros((ncats,12),dtype=float)
fig  = plt.figure(figsize=(15, 15), clear=True)
axes = fig.subplots(nrows=7, ncols=3)
for i in np.arange(0, ncats, 1, dtype=int):
    if i < 7:
    	j=i
    	k=0
    elif 6 < i < 14:
        j=i-7
        k=1
    elif 13 < i:
        j=i-14
        k=2
    	
    # Reading table data
    yaxis_mp  = fmp[i,:]
    yaxis_vg  = np.linspace(fveg[i,0], fveg[i,1], 12)
    ymin_vg   = np.linspace(fveg[i,0], fveg[i,0], 12)
    ymax_vg   = np.linspace(fveg[i,1], fveg[i,1], 12)
 
    # Reading LAI v1 observations
    yaxis_mean = np.where(fmean[i,:] < 0, np.nan, fmean[i,:])
    yaxis_max  = np.where(fmax[i,:]  < 0, np.nan, fmax[i,:] )
    yaxis_std  = np.where(fstd[i,:]  < 0, np.nan, fstd[i,:] )  
    
    # Reading LAI v3 observations
    if os.path.isfile(f'LAI_avg_v{version_extra}.csv'):
        yaxis_mean_extra = fmean_extra[i,:]
        yaxis_max_extra  = fmax_extra[i,:]
        yaxis_std_extra  = fstd_extra[i,:]

    # Reading Ngrids fiting to a specific category
    ngrid_per_cat = ngrids[i]
    if ngrid_per_cat == 0:
        ngrid_per_cat = '<0.01%'
    else:
    	ngrid_per_cat = str(ngrids[i])+'%'
    
    # Fitting MP data to VG data
    guess_mean  = np.mean(yaxis_mp)
    guess_std   = 3*np.std(yaxis_mp)/(2**0.5)/(2**0.5)
    guess_phase = 0
    guess_freq  = 1
    guess_amp   = 1    
    optimize_func = lambda x: x[0]*np.sin(x[1]*xaxis+x[2]) + x[3] - yaxis_mp
    est_amp, est_freq, est_phase, est_mean = leastsq(optimize_func, [guess_amp, guess_freq, guess_phase, guess_mean])[0]    
    data_fit = est_amp*np.sin(est_freq*xaxis+est_phase) + est_mean
    data_first_guess = guess_std*np.sin(xaxis+guess_phase) + guess_mean
    est_mean = np.mean(yaxis_vg)
    data_fit=est_amp*np.sin(est_freq*xaxis+est_phase)+est_mean
    
    # Fixing the fitted data
    fit_fixed[i,1:11] = data_fit[1:11]
    fit_fixed[i,0]    = data_fit[1] - yaxis_mp[1] + yaxis_mp[0]
    fit_fixed[i,11]   = data_fit[10] + yaxis_mp[11] - yaxis_mp[10]
    
    # Setting resources for the plot
    axes[j,k].set_ylim([-1, 10])
    axes[j,k].set_title(categories[i], y=0.8)
    axes[j,k].set_xticks(xaxis)
    
    # Setting the title for the axis
    if i in [6,13,19]:
        axes[j,k].set_xlabel('Months')
    if i in [0,1,2,3,4,5,6]:
        axes[j,k].set_ylabel('LAI')   
    
    # Plotting    
    axes[j,k].plot(xaxis, yaxis_mp, 's', color='grey', label=f'MP table monthly mean')				# mptable original    
    axes[j,k].plot(xaxis, ymin_vg,  '-', color='blue', label=f'VEGPARM table min')				# vegtable minimum
    axes[j,k].plot(xaxis, ymax_vg,  '-', color='red' , label=f'VEGPARM table max')				# vegtable maximum
    axes[j,k].plot(xaxis, fit_fixed[i,:], '.',  color='black',  label=f'Sinus fit fixed') 			# mptable fitted and fixed
    axes[j,k].plot(xaxis, yaxis_max,      'x',  color='orange', label=f'Monthly maximum v{data_version}') 	# observed maximum
    axes[j,k].errorbar(xaxis, yaxis_mean, yerr=yaxis_std, fmt='.', \
				color='orange', ecolor='orange', label=f'Monthly mean v{data_version}')		# observed mean with error bars  
    if os.path.isfile(f'LAI_avg_v{version_extra}.csv'):
        axes[j,k].plot(xaxis, yaxis_max_extra,   'x',  color='green',  label=f'Monthly maximum v{version_extra}')						# extra observed maximum
        axes[j,k].errorbar(xaxis, yaxis_mean_extra, yerr=yaxis_std_extra, fmt='.', color='green', ecolor='green', label=f'Monthly mean v{version_extra}')	# extra observed mean with error bars

    # Adding info on ngrids in form of txt in the upper left corner    
    axes[j,k].text(0.02, 0.9, ngrid_per_cat, horizontalalignment='left', verticalalignment='top',transform=axes[j,k].transAxes)

# Saving mptable fitted and fixed values to a table    
np.savetxt("LAI_MPfit2veg.csv", fit_fixed, delimiter =" ", fmt='%6.2f')

# Get Lines and lables for the legend       
lines, labels = axes[j,k].get_legend_handles_labels()    

# Remove the the last plot since there is no data    
axes[6,2].set_axis_off()

# Place the legend in the lower right corner 
fig.legend(lines, labels, loc = [0.775,0.055], fontsize='small') 

# Adjusting the space between the subplots and saving the figure   
fig.subplots_adjust(hspace=0.4)   

# Save figure as pdf file      
plt.savefig('LAI_table.pdf', bbox_inches='tight')
plt.show()
