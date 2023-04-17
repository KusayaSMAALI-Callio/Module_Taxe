query 8062637 "CAGTX_Sales Ord. Frst Inv Date"
{

    OrderBy = Ascending(Order_No), Descending(Posting_Date);

    elements
    {
        dataitem(Sales_Invoice_Header; "Sales Invoice Header")
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

