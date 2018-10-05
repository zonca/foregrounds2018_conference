#!/bin/bash

#SBATCH --partition=debug

#SBATCH --account=mp107
#SBATCH --nodes=1
#SBATCH --constraint=knl,quad,cache
#SBATCH --time=00:10:00
#SBATCH --job-name=pico-focalplane
#SBATCH --output=pico-focalplane-%j.log

set -o errexit
set -v

srun -n 1 -N 1 toast_fake_focalplane.py --minpix 50 --out fpfg2018 \
    --fwhm 9.5 --fwhm_sigma 0.03 \
    --fov 12.15 \
    --psd_fknee 0.010 --psd_NET 33.8e-6 --psd_fmin 1.0e-5 \
    --bandcenter_ghz 89.6 --bandcenter_sigma 0.01 \
    --bandwidth_ghz 22.4 --bandwidth_sigma 0.02 \
    --random_seed 11111
