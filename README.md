# Bash REST server
![GitHub top language](https://img.shields.io/github/languages/top/Vonvikken/bash_rest_server)
![GitHub](https://img.shields.io/github/license/Vonvikken/bash_rest_server)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/Vonvikken/bash_rest_server)
![GitHub last commit (by committer)](https://img.shields.io/github/last-commit/Vonvikken/bash_rest_server?color=firebrick)

Simple and light Bash REST server for inventory management

## Description
I wanted to create a tool for keeping track of an inventory, and I wanted the data to be readily available in my phone or my PC whenever I needed it.

Since I have an old Raspberry Pi 2 always connected to my home network, I opted to use it as a server. Finally, being my server an old Raspberry Pi 2, onto which several utilities are
continuously running, I wanted my tool to be as "light" as possible.

Thus, I wrote this tool in Bash, using all the tools it offers and leveraging `netcat` to manage the TCP connections. Of course this script is not suited for big or very complex
datasets, but it is very useful for a bit of household management!

### Use case: scale model kits inventory
I have a lot of unfinished kits and accessories stored in several boxes at home and in my basement. If I'm looking for a specific kit, I don't want to check the content of all of 
these boxes to find it, but I want to know the content of each box without opening it. How to do it?

1. First of all, I wrote my inventory in a CSV-like text file (I changed the field separators to `|`, in case the names contained any commas), e.g.:

   ```
   # position|description|brand
   box_1|MkIV "Male"|Emhar
   box_3|Somua S35|Tamiya
   box_2|LVT-4 "Water Buffalo"|Italeri
   box_1|8,8cm FlaK 36/37|Italeri
   box_2|Merkava Mk.II|Minicraft
   ```

   Being a plain text file, it's human-redable and simple to edit. I don't have hundreds of kits, after all, so this solution is quite manageable.
2. I created the main script, [`bash_rest_server.sh`](https://github.com/Vonvikken/bash_rest_server/blob/master/bash-rest-server.sh), which uses `netcat` to accept incoming requests,
   forwards them to a "handler" script for processing and send a response back. I wrote it as much generic and modular as    possible, so I will be able to add new use cases in the
   future if I want.
4. A handler script, [`handle_model.sh`](https://github.com/Vonvikken/bash_rest_server/blob/master/handle_model.sh), is called by the main one. It will process a specific request,
   read the data from the inventory file and create a response (either in JSON or in HTML format), then it will return such response back to the caller script.
5. The main script will run as a service on the Raspberry Pi 2, listening to a specific port (e.g. `20000`) and I will be able to use a browser to make a query to it
   (e.g. `http://my.raspberry:20000/model/box/2?fmt=html`) and display the result.

I put a label on each box with a QR-Code containing the related REST URL, and thus I will be able to read the content of each one. Alternatively, I can simply query for a specific
model or brand (e.g. `http://my.raspberry:20000/model/brand/Tamiya?fmt=html`) and read where it is stored.

### Add other use cases
Other use cases can be added by simply adding a new path in [`bash_rest_server.sh`](https://github.com/Vonvikken/bash_rest_server/blob/master/bash-rest-server.sh#L82) and the related
handler script.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/vonvikken/bash_rest_server. This project is intended to be a safe, welcoming space for collaboration,
and contributors are expected to adhere to the [code of conduct](https://github.com/Vonvikken/bash_rest_server/blob/master/code_of_conduct.md).

## Code of Conduct

Everyone interacting in the Bash REST Server project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/Vonvikken/bash_rest_server/blob/master/code_of_conduct.md).

## License

This project is distributed under the _MIT_ license.

