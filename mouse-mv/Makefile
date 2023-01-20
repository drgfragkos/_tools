all: main.cpp  resource.res
	g++ -o mouse-mv.exe resource.res main.cpp -mwindows
	strip mouse-mv.exe

resource.res: resource.rc mouse-mv.ico
	windres -i resource.rc --input-format=rc -o resource.res -O coff
