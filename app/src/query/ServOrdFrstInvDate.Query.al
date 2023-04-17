query 8062639 "CAGTX_Serv. Ord. Frst Inv Date"
{

    OrderBy = Ascending(Order_No), Descending(Posting_Date);

    elements
    {
        dataitem(Service_Invoice_Header; "Service Invoice Header")
        {
            column(Order_No; "Order No.")
            {
            }
            column(Posting_Date; "Posting Date")
            {
            }
            column(Document_Date; "Document Date")
            {
            }
            column(Order_Date; "Order Date")
            {
            }
        }
    }
}

