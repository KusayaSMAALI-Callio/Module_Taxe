query 8062638 "CAGTX_Purch Ord. Frst Inv Date"
{

    OrderBy = Ascending(Order_No), Descending(Posting_Date);

    elements
    {
        dataitem(Purch_Inv_Header; "Purch. Inv. Header")
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

