import sys
sys.path.insert(0, '..')

import math
import matplotlib as mp
import matplotlib.pyplot as plt
import numpy as np
import scipy.signal
from scipy.io import savemat, loadmat

import dragonradio

import drlog
import drgui

# This is the MCS used for packet headers
header_mcs = dragonradio.MCS('crc32', 'secded7264', 'h84', 'bpsk')

def dB2gain(dB):
    return 10.0**(dB/20.0)

def gain2dB(g):
    return 20.0*math.log(g)/math.log(10.0)

# Sampling frequency
Fs = 10e6

# Channel bandwidth
cbw = 800e3

# Channel guard width
gbw = 200e3

def plotResponse(taps, fs):
    plt.figure()
    
    for (h, title) in taps:
        w, h = scipy.signal.freqz(h, worN=8000)
    
        plt.plot(0.5*fs*w/np.pi, 20*np.log10(np.abs(h)), label=title)
        
    plt.xlim(0, 0.5*fs)
    plt.grid(True)
    plt.xlabel('Frequency (Hz)')
    plt.ylabel('Gain (dB)')
    plt.legend()
    plt.title('Frequency Response')

def fshift(sig, theta):
    """Frequency shift a signal."""
    return sig*np.exp(1j*2*np.pi*theta*(np.arange(0,len(sig))))

def demodulate(sig, Fc, Fs, m=7, fc=0.4, npfb=64, atten=60, use_scipy=True):
    """Demodulate a signal"""
    #mixed=sig


    # Frequency shift
    if use_scipy:
        mixed = fshift(sig, -Fc/Fs)
    else:
        nco = dragonradio.TableNCO(2*math.pi*Fc/Fs)
    
     #   mixed = nco.mix_down(sig)

    # Down-sample
    if use_scipy:
        resampled = scipy.signal.resample(mixed, int(len(sig)*cbw/Fs))
    else:
        downsamp = dragonradio.MultiStageResampler(cbw/Fs, m, fc, atten, npfb)
        #print(downsamp.rate, downsamp.delay, downsamp.rate*downsamp.delay)

        # Add padding to account for delay
        #mixed = np.append(mixed, np.zeros(math.ceil(downsamp.delay)))
    
        # Resample
     #   resampled = downsamp.resample(mixed)
    
        # Remove delay
        #resampled = resampled[math.floor(downsamp.rate*downsamp.delay):]
    
    # Demodulate mixed, down-sampled signal
    demod = dragonradio.OFDMDemodulator(True, False, 48, 6, 4)
    demod.header_mcs = header_mcs

    return demod.demodulate(resampled)

def modulate(hdr, payload, payload_mcs, Fc, Fs, m=7, fc=0.4, npfb=64, atten=60, use_scipy=True):
    """Modulate a packet"""
    mod = dragonradio.OFDMModulator(48, 6, 4)
    mod.header_mcs = header_mcs
    mod.payload_mcs = payload_mcs

    sig = mod.modulate(hdr, payload)

    # Up-sample
    if use_scipy:
        upsampled = scipy.signal.resample(sig, int(len(sig)*Fs/cbw))
    else:
        upsamp = dragonradio.MultiStageResampler(Fs/cbw, m, fc, atten, npfb)
    
        if Fs == cbw:
            upsampled = sig
        else:
            upsampled = upsamp.resample(np.append(sig, np.zeros(math.ceil(upsamp.delay))))
            upsampled = upsampled[math.floor(upsamp.rate*upsamp.delay):]
            upsampled = np.append(upsampled, np.zeros(10000))

    # Frequency shift
    if use_scipy:
        mixed = fshift(upsampled, Fc/Fs)
    else:
        nco = dragonradio.TableNCO(2*math.pi*Fc/Fs)
        mixed = nco.mix_up(upsampled)
    
    return mixed

# Resampler parameters
m=9       # Prototype filter semi-length
fc=0.4    # Prototype filter cutoff frequency, in range (0, 0.5)
npfb=64   # Number of filters in polyphase filterbank
atten=120 # Attenuation

# Modulate first packet


hdr1 = dragonradio.Header(1, 2, 0, 0, 1500)
mcs1 = dragonradio.MCS('crc32', 'none', 'v27', 'bpsk')
fc1 = 1e6

payload1 = b'0' * 1500

sig1 = modulate(hdr1, payload1, mcs1, fc1, Fs, m=m, fc=fc, npfb=npfb, atten=atten, use_scipy=True)

# Plot PSD of combined signal
fig = drgui.PSDPlot(*plt.subplots(), nfft=1024)
fig.plot(Fs, sig1)

#demodulate(sig1, fc1, Fs)

print(len(sig1))
data_ota = loadmat('qam128_ota.mat')
data_crop = np.ravel(np.array(data_ota['qam128_ota']))
#print(data_ota['qam128_ota'])
xyz=(demodulate(data_crop,fc,Fs))
print(xyz)

datafile = {
    "demod":xyz,
}
savemat("demod.mat",datafile)

# Modulate second packet
hdr2 = dragonradio.Header(2, 1, 0, 0, 1500)
mcs2 = dragonradio.MCS('crc32', 'rs8', 'none', 'qam256')
fc2 = 2e6+gbw

payload2 = b'0' * 1500

sig2 = modulate(hdr2, payload2, mcs2, fc2, Fs, m=m, fc=fc, npfb=npfb, atten=atten, use_scipy=True)

# Plot PSD of combined signal
fig = drgui.PSDPlot(*plt.subplots(), nfft=1024)
fig.plot(Fs, sig2)

def firfilter(sig, ft=100e3, atten=120, use_scipy=True):
    if True:
        N, beta = scipy.signal.kaiserord(atten, ft/(0.5*Fs))
        print(N, beta)

        h = scipy.signal.firwin(N, cbw/2, scale=True, window=('kaiser', beta), fs=Fs)
        #h = scipy.signal.firwin(N, cbw/2, window='hanning', fs=Fs, scale=True)
    else:
        N = 300
        fc = cbw
        bands = [0, (fc - ft)/2, (fc + ft)/2, Fs/2]

        #h = scipy.signal.firls(N, bands, [1, 1, 0, 0], fs=Fs)
        h = scipy.signal.remez(N, bands, [1, 0], fs=Fs)

    # Filter received signal
    plotResponse([(h, 'Kaiser')], Fs)

    if use_scipy:
        return scipy.signal.lfilter(h, [1.0], sig)
    else:
        filt = dragonradio.LiquidFIRFilter(h)
        return filt.execute(sig)

# Combine signals
l = max(len(sig1), len(sig2))

sig = dB2gain(-10)*np.append(sig1, np.zeros(l - len(sig1))) + dB2gain(-100)*np.append(sig2, np.zeros(l - len(sig2)))

# Plot PSD of combined signal
fig = drgui.PSDPlot(*plt.subplots(), nfft=1024)
fig.plot(Fs, sig)

# Shift signal down
nco = dragonradio.TableNCO(2*math.pi*fc2/Fs)
sig = nco.mix_down(sig)
    
# Plot PSD of shifted signal
fig = drgui.PSDPlot(*plt.subplots(), nfft=1024)
fig.plot(Fs, sig)

# Filter signal
sig_filtered = firfilter(sig, atten=30, use_scipy=True)

# Plot PSD of filtered signal
fig = drgui.PSDPlot(*plt.subplots(), nfft=1024)
fig.plot(Fs, sig_filtered)


#Attempt to demodulate second signal
demodulate(sig_filtered, 0, Fs)

# Design FIR filter
ft  = 100e3
atten = 60

# Create Kaiser filter
N, beta = scipy.signal.kaiserord(atten, ft/(0.5*Fs))
print(N, beta)

h_kaiser = scipy.signal.firwin(N, cbw/2, scale=True, window=('kaiser', beta), fs=Fs)
h_hanning = scipy.signal.firwin(N, cbw/2, window='hanning', fs=Fs, scale=True)

# Create least squares filter
if N % 2 == 0:
    N +=1
    
fc = cbw
bands = [0, (fc - ft)/2, (fc + ft)/2, Fs/2]

h_ls = scipy.signal.firls(N, bands, [1, 1, 0, 0], fs=Fs)
h_equi = scipy.signal.remez(N, bands, [1, 0], fs=Fs)

# Plor response
plotResponse([(h_kaiser, 'Kaiser'), (h_hanning, 'Hanning'), (h_ls, 'Least Squares')], Fs)

print(h_kaiser)
