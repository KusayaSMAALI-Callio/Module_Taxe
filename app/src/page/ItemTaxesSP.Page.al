page 8062616 "CAGTX_Item Taxes SP"
{
    Caption = 'Item Taxes';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "CAGTX_Item Tax V2";
    layout
    {
        area(content)
        {
            repeater(Group)
            {
                FreezeColumn = Description;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Type field';
                    Visible = false;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the No. field';
                    Visible = false;
                }
                field("Tax Code"; Rec."Tax Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Tax Code field';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Description field';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Variant Code field';
                }
                field("Item Category Code"; Rec."Item Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    ToolTip = 'Specifies the value of the Item Category Code field';
                }
                field("Effective Date"; Rec."Effective Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Effective Date field';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Unit of Measure Code field';
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Minimum Quantity field';
                }
                field("Rate Type"; Rec."Rate Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Rate Type field';
                }
                field("Rate Value"; Rec."Rate Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Value field';
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Tax: Record CAGTX_Tax;
    begin
        if FromItem."No." <> '' then begin
            Rec.Type := Rec.Type::Item;
            Rec."No." := FromItem."No.";
        end;

        Rec.CalcFields(Description);
        if Tax.Get(Rec."Tax Code") then begin
            Rec."Rate Type" := Tax."Default Rate Type";
            Rec."Rate Value" := Tax."Default Rate Value";
        end;
    end;

    procedure SetFromItem(Item: Record Item)
    begin
        FromItem := Item;
    end;

    var
        FromItem: Record item;
}