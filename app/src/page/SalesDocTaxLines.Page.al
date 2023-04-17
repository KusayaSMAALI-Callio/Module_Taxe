page 8062645 "CAGTX_Sales Doc Tax Lines"
{

    Caption = 'Tax Lines';
    DelayedInsert = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SourceTable = "Sales Line";
    SourceTableView = SORTING("Document Type", "Document No.", "Line No.")
                      ORDER(Ascending)
                      WHERE("CAGTX_Tax Line" = FILTER(true));

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("CAGTX_Tax Line"; Rec."CAGTX_Tax Line")
                {
                    Visible = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the CAGTX_Tax Line field';
                }
                field("CAGTX_Tax Code"; Rec."CAGTX_Tax Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the CAGTX_Tax Code field';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Type field';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the No. field';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Description field';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Quantity field';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Unit Price field';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Amount field';
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Amount Including VAT field';
                }
                field("CAGTX_Origin Tax Line"; Rec."CAGTX_Origin Tax Line")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the CAGTX_Origin Tax Line field';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Item Charge &Assignment")
            {
                AccessByPermission = TableData "Item Charge" = R;
                Caption = 'Item Charge &Assignment';
                Image = TransferToLines;
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Executes the Item Charge &Assignment action';

                trigger OnAction()
                begin
                    Rec.ShowItemChargeAssgnt();
                end;
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        Rec.SuspendStatusCheck(true);
    end;
}