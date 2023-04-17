page 8062637 "CAGTX_Tax Assgn. to Third Part"
{

    Caption = 'Tax Assignment To Third Party';
    PageType = Worksheet;
    SourceTable = "CAGTX_Tax Assign. Third Party";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(Filters)
            {
                Caption = 'Filters';
                field(TaxCodeFilter; TaxCodeFilter_G)
                {
                    Caption = 'Tax Code Filter';
                    TableRelation = CAGTX_Tax;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Tax Code Filter field';

                    trigger OnValidate()
                    begin
                        SetPageFilter(true);
                    end;
                }
                field(TypeFilter; TypeFilter_G)
                {
                    Caption = 'Type Filter';
                    OptionCaption = ' ,Third Party,Posting Group,All';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Type Filter field';

                    trigger OnValidate()
                    begin
                        SetPageFilter(true);
                    end;
                }
                field(LinktoTable; LinktoTable_G)
                {
                    Caption = 'Third Party Filter';
                    OptionCaption = ' ,Customer,Vendor';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Third Party Filter field';

                    trigger OnValidate()
                    begin
                        SetPageFilter(true);
                    end;
                }
            }
            repeater(Group)
            {
                field("Tax Code"; Rec."Tax Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Tax Code field';
                }
                field("Link to Table"; Rec."Link to Table")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Link to Table field';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Type field';

                    trigger OnValidate()
                    begin
                        GetEditableNo();
                    end;
                }
                field("No."; Rec."No.")
                {
                    Editable = NoEditable_G;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the No. field';
                }
                field(Description; GetDescription())
                {
                    Caption = 'Description';
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Description field';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        GetEditableNo();
    end;

    trigger OnOpenPage()
    begin
        TaxCodeFilter_G := CopyStr(Rec.GetFilter(Rec."Tax Code"), 1, MaxStrLen(TaxCodeFilter_G));// TODO refactoring a prévoir 
        SetPageFilter(false);
    end;

    var
        TypeFilter_G: Option " ","Third Party","Posting Group",All;
        TaxCodeFilter_G: Code[20];
        [InDataSet]
        NoEditable_G: Boolean;
        LinktoTable_G: Option " ",Customer,Vendor;

    local procedure SetPageFilter(p_Update: Boolean)
    begin
        Rec.Reset();
        if TaxCodeFilter_G <> '' then
            Rec.SetRange("Tax Code", TaxCodeFilter_G);
        if TypeFilter_G <> 0 then
            Rec.SetRange(Type, TypeFilter_G - 1);
        if LinktoTable_G <> 0 then
            Rec.SetRange("Link to Table", LinktoTable_G);

        if p_Update then
            CurrPage.Update();
    end;

    local procedure GetEditableNo()
    begin
        NoEditable_G := Rec.Type <> Rec.Type::All;
    end;

    local procedure GetDescription() ReturnValue: Text
    var
        Customer_L: Record Customer;
        Vendor_L: Record Vendor;
    begin
        ReturnValue := '';
        case Rec.Type of
            Rec.Type::"Third Party":
                case Rec."Link to Table" of
                    Rec."Link to Table"::Customer:
                        if Customer_L.Get(Rec."No.") then
                            ReturnValue := Customer_L.Name;
                    Rec."Link to Table"::Vendor:
                        if Vendor_L.Get(Rec."No.") then
                            ReturnValue := Vendor_L.Name;
                end;
        end;
    end;
}