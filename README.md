# HexLator
HexLator is a compiler for Hex Casting hexes that runs in ComputerCraft. It comes packaged with HexGet, a utility to download and compile a hex to a focus, as well as HexxyEdit, an in-game hex editor. Both will compile a tweaked .hexpattern format that includes additional syntax for embedded iotas and macros.

## Requirements
The Focal Port from https://github.com/SamsTheNerd/ducky-periphs is required to write to Foci.

## Installation
Download and run the installer on a ComputerCraft computer (this will replace the existing startup.lua file at root):
```
wget https://raw.githubusercontent.com/Vizoee/HexLator/main/install_hexlator.lua
```

## Usage example
Compile a .hexpattern from the internet into a Focus:
```
hexget https://github.com/Vizoee/HexLator/blob/main/example.hexpattern
```

## Config
```.config/hexlator.json``` is a config file containing few options for easier working with this tool. This is very usefull because of ```Copy relative path``` option many IDE have. When you fill config, you can, instead of running ```hexget https://github.com/Vizoee/HexLator/blob/main/example.hexpattern```, run ```hexget example.hexpattern```. 

Values:
- default_repo: string - contains link to repo that given file belongs to as well as all #git files. example: ```"default_repo":"https://github.com/Vizoee/HexLator"```
- branch: string - contains branch from which toll should download files. example: ```"branch":"main"```
- cashed: boolean - dictates weather #git should be redownloaded each time. example: ```"cashed":false```
- token: string - github token for reading repo. Very usefull as without it there is limit of 60 requests per hour, with token its 5000 requests. example: ```"token":"github_pat_1234..."```

## Syntax

Symbols are written in the hexpattern format:

```
Mind's Reflection
Compass Purification
```

Bookkeeper's Gambit and Numerical Reflection are used as such. The latter supports positive and negative integers:
```
Bookkeeper's Gambit: -vv---
Numerical Reflection: -367
```

Additionally Sekhmet's Gambit, Geb's Gambit and Nut's Gambit are also supported (mininal value is 2):
```
Sekhmet's Gambit: 3
Geb's Gambit: 5
Nut's Gambit: 3
```

The following frequently used symbols have aliases you can use instead if you so choose:
```
{  = Introspection
}  = Retrospection
>> = Flock's Disintegration
```

Thus, a common pattern for embedding iotas looks like: ```{@vec(1, 2, 3)} >>```

### Iota Syntax
Iotas are written in the following format:
```
@num(1)                        //Number
@vec(1,2,3)                    //Vector
[1, @vec(1, 2, 3)]             //List
@entity("uuid")                //Entity 
@null                          //Null
@garbage                       //Garbage
@true                          //Bool
@pattern(NORTHEAST,qaq)        //Symbol via pattern
Numerical Reflection           //Pattern via name
@str(hello world)              //String
@gate("id")                    //Gate via string
@entity_type("type")           //Entity type via string
@iota_type("type")             //Iota type via string
@item_type("type", isItem)     //Item and Block types via string and bool
@mote("moteUuid", "itemID")    //Mote via strings
@matrix(col, row, <matrix>)    //Matrix
@hexicon(ehe)                  //String to hexicon pattern
```

### Macros/Functions
```#def(<name>)(<body>)``` will result in all instances of ```$<name>``` being replaced with ```<body>```. This can be paired with ```#file``` to load a 'library' of functions from another file to be made available in your current file. Functions can accept arguments by including ```<1>, <2>, ...``` within the body of the function. Arguments can be passed to the function as ```$func(arg1)(arg2)...```.

```#file(<filename1>, <filename2>, ...)``` will look for ```<filename>```(s) and replace itself with their contents in order. This can be used to directly insert data at a given position, but is more commonly used to include 'libraries'. The following is an example, assuming that ```example.hexpattern``` is to be compiled.

```#wget(<filepath>)(<url>)``` will attempt to use the wget utility packaged with the default ComputerCraft ROM to download and load a given file at time of compilation (overwriting any existing file at the same path). This makes it far easier to set up a build environment, and can allow for a complex hex AND its dependancies to all be downloaded with a single HexGet command.

If statements and for loops are not implicit constructs, but they are implemented as functions and documented in [syntax_utils.hexpattern](https://github.com/Shirtsy/HexLator/blob/main/utils/syntax_utils.hexpattern), you can make them available to your code by including ```#wget(syntax_utils.hexpattern)(https://github.com/Shirtsy/HexLator/raw/dev/utils/syntax_utils.hexpattern)``` in your file.

```#git(<filepath>)``` will attempt to download and load a given file from same repository at time of compilation. This makes it far easier to set up a build environment, and can allow for a complex hex AND its dependancies to all be downloaded with a single HexGet command.

example.hexpattern:
```
#file(counter.hexpattern)

{@num(10)} >>
$return_list
```
counter.hexpattern:
```
#def(return_list)(
{
    Jester's Gambit
    Gemini Gambit
}
{
    Gemini Decomposition
    Abacus Purification
    Integration Distillation
}
Single's Purification
Thoth's Gambit
@pattern(WEST,ae)
{
    >>
}
Jester's Gambit
Thoth's Gambit
Vacant Reflection
Jester's Gambit
Hermes' Gambit
)
```
Output:
```
[0,1,2,3,4,5,6,7,8,9]
```

### TODO List

- Add argument to disable usage of github api
- Add fast dictionary declaration
- Add code wrapper support
- Fix words in @str(...) being interpreted as patterns
- Add to hexget ability to return iota instead of writing it to focus
- Improve caching
- Add detection for rate limit error 