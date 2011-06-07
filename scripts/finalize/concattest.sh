#!/bin/bash

numiter=4

h2m_tx=" "
		echo ${h2m_tx}
		
		for ((i=1; i <= ${numiter}; i=i+1)); do
			h2m_tx="${h2m_tx} iter${i}_Affine.txt"
			
			echo ${h2m_tx}
		done
		
		echo ${h2m_tx}