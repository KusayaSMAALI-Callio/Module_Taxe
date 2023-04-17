query 8062641 "CAGTX_Purch Ret. Frst Cr. Date"
{

    OrderBy = Ascending(Return_Order_No), Descending(Posting_Date);

    elements
    {
        dataitem(Purch_Cr_Memo_Hdr; "Purch. Cr. Memo Hdr.")
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

