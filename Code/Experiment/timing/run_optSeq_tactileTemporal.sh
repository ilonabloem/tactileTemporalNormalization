#! /bin/bash -l

# optseg command to generate design matrices
optseq2 \
    --ntp 300 \
    --tr 1 \
    --psdwin 0 20 1 \
    --ev OnePulse_1 2 3 \
    --ev OnePulse_2 2 3 \
    --ev OnePulse_3 2 3 \
    --ev OnePulse_4 2 3 \
    --ev OnePulse_5 2 3 \
    --ev OnePulse_6 2 3 \
    --ev TwoPulse_1 2 3 \
    --ev TwoPulse_2 2 3 \
    --ev TwoPulse_3 2 3 \
    --ev TwoPulse_4 2 3 \
    --ev TwoPulse_5 2 3 \
    --ev TwoPulse_6 2 3 \
    --ev BlankPulse 2 3 \
    --o task-tact \
    --nkeep 20 \
    --tsearch 1 \
    --tnullmin 3 \
    --tnullmax 15 \
    --sum sumFile.sum \
    --log logFile.log
