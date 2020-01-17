pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address payable public owner;
    uint   PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    
    uint public idGenerator;


    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Buyer{
        address payable consumer;
        uint ticketsOwn;
    }
    struct Event{
        string description;
        string website;
        uint totalTickets;
        mapping (address => Buyer) buyers;
        uint sales;
        bool isOpen;
    }


    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping (uint => Event) events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets,uint amountRefunded);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier isOwner{
        require(msg.sender == owner,'Not an owner.');
        _;
    }
    modifier purchaseable (uint id, uint numOfTickets){
        
        require(events[id].isOpen == true, 'Event is not open to public yet.');
        require(events[id].totalTickets >= numOfTickets, 'Not enough tickets to purchase');
        require(msg.value >= (PRICE_TICKET * numOfTickets) , 'Not enough funds in account');
        _;
    }
    
    modifier checkValue(uint id,uint numOfTickets) {
        _;
        uint amountToRefund = msg.value - (PRICE_TICKET * numOfTickets);
        if(amountToRefund > 0){
            events[id].buyers[msg.sender].consumer.transfer(amountToRefund);
        }
    }

    constructor () public{
        owner=msg.sender;
    }

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string memory _desc,string memory _url,uint numOfTickets) isOwner public returns(uint){
        uint id=idGenerator;
        events[id].description=_desc;
        events[id].website=_url;
        events[id].totalTickets=numOfTickets;
        events[id].isOpen=true;
        idGenerator++;
        emit LogEventAdded(_desc,_url,numOfTickets,id);
        return id;
    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. tickets available
            4. sales
            5. isOpen
    */
    function readEvent(uint _id) view public
        returns(string memory description, string memory website, uint totalTickets, uint sales, bool isOpen)
    {
         description=events[_id].description;
         website=events[_id].website;
         totalTickets=events[_id].totalTickets;
         sales=events[_id].sales;
        isOpen=events[_id].isOpen;
        return (description,website,totalTickets,sales,isOpen);
       // return ;
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */

     
    function buyTickets(uint id,uint numOfTickets) purchaseable(id,numOfTickets) checkValue(id,numOfTickets) payable public {
        events[id].totalTickets-=numOfTickets;
        events[id].sales+=numOfTickets;
        //Buyer memory buy=events[id].buyers[msg.sender];
        events[id].buyers[msg.sender].consumer=msg.sender;
        events[id].buyers[msg.sender].ticketsOwn=numOfTickets;
        emit LogBuyTickets(events[id].buyers[msg.sender].consumer,id,events[id].buyers[msg.sender].ticketsOwn);
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint id) public {
        //Buyer memory buy = events[id].buyers[msg.sender];
        uint numberOfTickets = events[id].buyers[msg.sender].ticketsOwn;
        require(numberOfTickets > 0,'Never purchased a ticket');
        events[id].totalTickets += numberOfTickets;
        events[id].sales -= numberOfTickets;
        uint amountToRefund = PRICE_TICKET * numberOfTickets;
        events[id].buyers[msg.sender].consumer.transfer(amountToRefund);
        emit LogGetRefund(events[id].buyers[msg.sender].consumer,id,events[id].buyers[msg.sender].ticketsOwn,amountToRefund);
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint id) view public returns (uint){
        return events[id].buyers[msg.sender].ticketsOwn;
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint id) isOwner public{
        events[id].isOpen=false;
        uint transferAmount=events[id].sales * PRICE_TICKET;
        owner.transfer(transferAmount);
        emit LogEndSale(owner,transferAmount,id);
    }
}
