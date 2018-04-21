#!/bin/sh
curl -X POST http://localhost:3000/users -d '{"data":{"name":"Montana Runolfsson","email":"cesar.rice@wolfhills.info"}}'
echo "\n"
curl -X POST http://localhost:3000/users -d '{"data":{"name":"Dorothea Whitaker","email":"mthurn@live.com"}}'
echo "\n"
curl -X POST http://localhost:3000/users -d '{"data":{"name":"Prue Lorinda","email":"neonatus@live.com"}}'
echo "\n"
curl -X POST http://localhost:3000/users -d '{"data":{"name":"Gray Julio","email":"telbij@mac.com"}}'
echo "\n"
curl -X POST http://localhost:3000/users -d '{"data":{"name":"Archer Fabio","email":"inico@icloud.com"}}'
echo "\n"
curl -X POST http://localhost:3000/users -d '{"data":{"name":"Cruzita Phyllidak","email":"ajohnson@yahoo.ca"}}'
