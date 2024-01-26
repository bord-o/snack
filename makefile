run: build
	chmod +x ./_build/snack && cd ./_build && ./snack

build:
	mkdir -p ./_build/
	mlton -output ./_build/snack ./src/snack.mlb 

clean:
	rm -rf ./_build
	
