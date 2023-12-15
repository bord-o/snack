build:
	mlton -output ./_build/smlacker ./src/smlacker.mlb 


run: build
	chmod +x ./_build/smlacker && cd ./_build && ./smlacker
	
