query 8062636 "CAGTX_Purch Tax Line Chk View"
{


    elements
    {
        dataitem(CAGTX_Purch_Doc_Tax_Detail; "CAGTX_Purch. Doc. Tax Detail")
        {
            SqlJoinType = InnerJoin;
            column(Document_Type_Filter; "Document Type")
            {
            }
            column(Document_No_Filter; "Document No.")
            {
            }
            column(Line_No_Filter; "Tax Line No.")
            {
            }
            dataitem(Purchase_Line; "Purchase Line")
            {
                DataItemLink = "Document Type" = CAGTX_Purch_Doc_Tax_Detail."Document Type", "Document No." = CAGTX_Purch_Doc_Tax_Detail."Document No.", "Line No." = CAGTX_Purch_Doc_Tax_Detail."Line No.";
                SqlJoinType = LeftOuterJoin;
                column(Sum_Outstanding_Quantity; "Outstanding Quantity")
                {
                    Method = Sum;
                }
                column(Sum_Quantity; Quantity)
                {
                    Method = Sum;
                }
            }
        }
    }
}

