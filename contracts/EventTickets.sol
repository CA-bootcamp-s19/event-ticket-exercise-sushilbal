pragma solidity ^0.5.0;

    /*
        The EventTickets contract keeps track of the details and ticket sales of one event.
     */

contract EventTickets {

    /*
        Create a public state variable called owner.
        Use the appropriate keyword to create an associated getter function.
        Use the appropriate keyword to allow ether transfers.
     */
     address payable public owner;

    uint  TICKET_PRICE = 100 wei;

    /*
        Create a struct called "Event".
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
    

    Event myEvent;

    /*
        Define 3 logging events.
        LogBuyTickets should provide information about the purchaser and the number of tickets purchased.
        LogGetRefund should provide information about the refund requester and the number of tickets refunded.
        LogEndSale should provide infromation about the contract owner and the balance transferred to them.
    */
    event LogBuyTickets(address buyer,uint numOfTickets);
    event LogGetRefund(address refundedTo, uint numOfTicketsRefundedFor);
    event LogEndSale(address owner, uint balanceTranfer);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier isOwner{
        require(msg.sender == owner,'Only owner is allowoed');
        _;
    }

     modifier purchaseable (uint numOfTickets){
        require(myEvent.isOpen == true, 'Event is not open to public yet.');
        require(myEvent.totalTickets >= numOfTickets, 'Not enough tickets to purchase');
        require(msg.value >= (TICKET_PRICE * numOfTickets) , 'Not enough funds in account');
        _;
    }
    modifier checkValue(uint numOfTickets) {
        _;
        uint amountToRefund = msg.value - (TICKET_PRICE * numOfTickets);
        if(amountToRefund > 0){
            myEvent.buyers[msg.sender].consumer.transfer(amountToRefund);
        }
    }
    /*
        Define a constructor.
        The constructor takes 3 arguments, the description, the URL and the number of tickets for sale.
        Set the owner to the creator of the contract.
        Set the appropriate myEvent details.
    */
    constructor (string memory _description,string memory _url,uint _numOfTickets) public{
        owner=msg.sender;
        myEvent.description=_description;
        myEvent.website=_url;
        myEvent.totalTickets=_numOfTickets;
        myEvent.isOpen=true;
    }

    /*
        Define a function called readEvent() that returns the event details.
        This function does not modify state, add the appropriate keyword.
        The returned details should be called description, website, uint totalTickets, uint sales, bool isOpen in that order.
    */
    function readEvent() view public
        returns(string memory description, string memory website, uint totalTickets, uint sales, bool isOpen)
    {
         description=myEvent.description;
         website=myEvent.website;
         totalTickets=myEvent.totalTickets;
         sales=myEvent.sales;
         isOpen=myEvent.isOpen;
        return (description,website,totalTickets,sales,isOpen);
    }

    /*
        Define a function called getBuyerTicketCount().
        This function takes 1 argument, an address and
        returns the number of tickets that address has purchased.
    */
    function getBuyerTicketCount(address _buyer) view public returns(uint){
        return myEvent.buyers[_buyer].ticketsOwn;
    }

    /*
        Define a function called buyTickets().
        This function allows someone to purchase tickets for the event.
        This function takes one argument, the number of tickets to be purchased.
        This function can accept Ether.
        Be sure to check:
            - That the event isOpen
            - That the transaction value is sufficient for the number of tickets purchased
            - That there are enough tickets in stock
        Then:
            - add the appropriate number of tickets to the purchasers count
            - account for the purchase in the remaining number of available tickets
            - refund any surplus value sent with the transaction
            - emit the appropriate event
    */
   
    function buyTickets(uint numOfTickets) purchaseable(numOfTickets) checkValue(numOfTickets) payable public {
        myEvent.totalTickets-=numOfTickets;
        myEvent.sales+=numOfTickets;
        myEvent.buyers[msg.sender].ticketsOwn=numOfTickets;
        myEvent.buyers[msg.sender].consumer=msg.sender;
        emit LogBuyTickets(msg.sender,numOfTickets);
    }


    /*
        Define a function called getRefund().
        This function allows someone to get a refund for tickets for the account they purchased from.
        TODO:
            - Check that the requester has purchased tickets.
            - Make sure the refunded tickets go back into the pool of avialable tickets.
            - Transfer the appropriate amount to the refund requester.
            - Emit the appropriate event.
    */
    function getRefund() public {
        
        uint numberOftickets=myEvent.buyers[msg.sender].ticketsOwn;
        require(numberOftickets > 0 , 'Never purchased a ticket');
        myEvent.totalTickets+=numberOftickets;
        myEvent.sales-=numberOftickets;
        uint amountToRefund = TICKET_PRICE * numberOftickets;
        myEvent.buyers[msg.sender].consumer.transfer(amountToRefund);
        emit LogGetRefund(msg.sender,numberOftickets);
    }

    /*
        Define a function called endSale().
        This function will close the ticket sales.
        This function can only be called by the contract owner.
        TODO:
            - close the event
            - transfer the contract balance to the owner
            - emit the appropriate event
    */
    function endSale() isOwner public{
        myEvent.isOpen=false;
        uint transferAmount=myEvent.sales * TICKET_PRICE;
        owner.transfer(transferAmount);
        emit LogEndSale(owner,transferAmount);
    }
}
