run: build
	chmod +x ./_build/snack && cd ./_build && ./snack

build:
	mlton -output ./_build/snack ./src/snack.mlb 
	
