shell-scripts
=============
Miscellaneous shell scripts, typically written in bash.

These files are in various states of neglect and shouldn't be used in any production capacity without thorough review.

#Directory layout:

ambilight: proof of concept work to slice apart a farm to obtain RGB values for lighting a LED strip. At last benchmark, this processed roughly 3 frames per second on an i7-2760QM, without issuing any updates to a LED strip. With this being intended to have been run on a Raspberry Pi, this approach will not evolve further here.

image-tools: scripts intended to manipulate still images

lib: bash script functions intended to be sourced by other scripts to avoid repeat work

media-tools: scripts intended to manipulate audio/video media

utilities: scripts intended to aid a user operating a system
