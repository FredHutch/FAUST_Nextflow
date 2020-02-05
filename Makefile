documentation_table_of_contents:
	doctoc README.md
	doctoc documentation

clean:
	rm -fr .DS_Store	 # Remove mac os files
	rm -fr .nextflow	 # Remove nextflow working directory
	rm -fr work			 # Remove nextflow work files
	rm -fr FAUST_RESULTS # Remove task artifacts
	rm -f .nextflow.log* # Remove nextflow log files
	rm -f *.html*        # Remove nextflow report and timeline files
	rm -f *.txt*         # Remove nextflow trace files
