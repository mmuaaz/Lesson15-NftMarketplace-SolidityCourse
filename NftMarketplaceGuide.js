;/======================================================GUIDE==================================================================/
// make boiler plate for the new project
// copy files like .gitignore, .prettierrc etc from previous projects
//  Copy commands from lesson 9 git repo of the course and then run
// RUN COMM:yarn add --dev @openzeppelin/contracts
;/Writing Listing into the Marketplace SC/
// we should write the SC for listing into the marketplace; taking into account the following:
//checking if the listing is not already made
//checking if the one who is listing is actually the owner of the NFT
// FOR BUYING:   we need to check if the item is listed
;/-----Pull Over Push /
// when a buyer buys the NFT, our SC is designed to hold the payment in the seller's account to withdraw
//  this is to shift the risk of transferring ether to the user
//--- instead what we code in our SC is that seller has to withdraw whatever he has earned by selling the NFT
;/safeTransferFrom function vs transferFrom/
// Refer to IERC721 SC for the recommendations; in the notes of "safeTransferFrom function", it is written that the use of this function is discouraged, why we dont know
// Patrick did say that we should this function as it is a lot safer and it checks if the NFT has been trnasfered also it is going to throw an error if something goes wrong
;/----------------------Re-entrancy Attacks----------------/
// Two types are common  ----------Re-entrancy Attacks
//                       ----------Oracle Attacks
// ORACLE ATTACKS happens if you dont use a decentralized Oracle
// ======RE-Entrancy ATTACK shown by the code, found in the git repo of the course; so if the SC has a specific vulnerability; attackers are able to use "fallback" function
//and re-enter the transfer/withdraw functions, thereby manipulating the SC to transfer before reset the balance,
;/-/ //easier way is to always reset the balance first, then make any transfer/withdraw
;/-/ // the second way that OPEN ZEPPELIN does in their SC, is =========MUTEX LOCK==========
//  this is done by the use of  Modifiers; what they do is that use a boolean with any name;, the function withdraw/transfer requires certain value of the boolean, when the
//function is called it immediately updated to something lets say "true"
// once the code of the function is finished then update the value again and if the same SC tried to call the function again it would require to it to be "true" or something so
// they cant do it again and again before the function finish running the code
;/----------------------------Writing scripts/
// we are writing tests in order to test some stuff out, we are gonna need this stuff later on when we deploy the SC on the front end
