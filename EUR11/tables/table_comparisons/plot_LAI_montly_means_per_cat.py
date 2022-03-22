import numpy as np
import matplotlib.pyplot as plt
from numpy import arange
from scipy.optimize import curve_fit
from scipy.optimize import leastsq
from numpy import sin

# Load all data
fmp     = np.loadtxt('LAI_MPTBL.csv')
fvg     = np.loadtxt('LAI_VEGTBL.csv')
fmn_v1  = np.loadtxt('LAI_OBSmean_v01.csv')
fmx_v1  = np.loadtxt('LAI_OBSmax_v01.csv')
fstd_v1 = np.loadtxt('LAI_OBSmean_std_v01.csv')
fmn_v3  = np.loadtxt('LAI_OBSmean_v03.csv')
fmx_v3  = np.loadtxt('LAI_OBSmax_v03.csv')
fstd_v3 = np.loadtxt('LAI_OBSmean_std_v03.csv')
ngrids  = np.loadtxt('Ngrids_per_cat.txt')
 
# Read LU category names
categories = []
with open('LU_CATS.txt') as f:
    categories = f.readlines()
ncats = len(categories)

# Define x axis and labels to be months
xaxis = np.linspace(1, 12, 12)
xlabels = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']


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
    yaxis_vg  = np.linspace(fvg[i,0], fvg[i,1], 12)
    ymin_vg   = np.linspace(fvg[i,0], fvg[i,0], 12)
    ymax_vg   = np.linspace(fvg[i,1], fvg[i,1], 12)
 
    # Reading LAI v1 observations
    yaxis_mean_v1 = fmn_v1[i,:]
    yaxis_max_v1  = fmx_v1[i,:]
    yaxis_std_v1  = fstd_v1[i,:]

    # Reading LAI v3 observations
    yaxis_mean_v3 = fmn_v3[i,:]
    yaxis_max_v3  = fmx_v3[i,:]
    yaxis_std_v3  = fstd_v3[i,:]

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
    axes[j,k].plot(xaxis, yaxis_mp, 's', color='grey', label="MP table monthly mean")	# mptable original    
    axes[j,k].plot(xaxis, ymin_vg,  '-', color='blue', label="VEGPARM table min")	# vegtable minimum
    axes[j,k].plot(xaxis, ymax_vg,  '-', color='red' , label="VEGPARM table max")	# vegtable maximum
    axes[j,k].plot(xaxis, fit_fixed[i,:], '.',  color='black',  label="Sinus fit fixed") 	# mptable fitted and fixed
    axes[j,k].plot(xaxis, yaxis_max_v1,   'x',  color='orange', label="Monthly maximum v01") 	# v1 observed maximum
    axes[j,k].plot(xaxis, yaxis_max_v3,   'x',  color='green',  label="Monthly maximum v03")	# v3 observed maximum
    axes[j,k].errorbar(xaxis, yaxis_mean_v1, yerr=yaxis_std_v1, fmt='.', color='orange', ecolor='orange', label="Monthly mean v01")	# v1 observed mean with error bars  
    axes[j,k].errorbar(xaxis, yaxis_mean_v3, yerr=yaxis_std_v3, fmt='.', color='green', ecolor='green',   label="Monthly mean v03")	# v3 observed mean with error bars

    # Adding info in form of txt in the upper left corner    
    axes[j,k].text(0.02, 0.9, ngrid_per_cat, horizontalalignment='left', verticalalignment='top',transform=axes[j,k].transAxes)

np.savetxt("LAI_MPfit2veg.csv", fit_fixed, delimiter =" ", fmt='%6.2f')

# Get Lines and lables for the legend       
lines, labels = axes[j,k].get_legend_handles_labels()    

# Remove the the last plot since there is no data    
axes[6,2].set_axis_off()

# Place the legend in the lower right corner 
fig.legend(lines, labels, loc = [0.775,0.055], fontsize='small') 

# Adjusting the space between the subplots and saving the figure   
fig.subplots_adjust(hspace=0.4)   
           
plt.savefig('LAI.pdf', bbox_inches='tight')
#plt.legend()
plt.show()



    

