query 8062640 "CAGTX_Sales Ret. Frst Cr. Date"
{

    OrderBy = Ascending(Return_Order_No), Descending(Posting_Date);

    elements
    {
        dataitem(Sales_Cr_Memo_Header; "Sales Cr.Memo Header")
        {
            column(Return_Order_No; "Return Order No.")
            {
            }
            column(Posting_Date; "Posting Date")
            {
            }
            column(Document_Date; "Document Date")
            {
            }
        }
    }
}

