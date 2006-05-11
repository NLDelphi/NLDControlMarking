(*****************************************************************************
Omschrijving:
  Een MarkableControl toont m.b.v. een Timer-event een 'wandelend'
selectiekader rond een T(Win)Control van 2 pixels breed, ongeveer gelijk aan
het markeringskader van MS Excel. In een andere vorm wordt dit ook wel
Marching Ants genoemd.
Zie ook http://www.nldelphi.com/Forum/showthread.php?threadid=16633

Gebruik:
  Het MarkableControl is er in twee versies, een TNLDMarkableGraphicControl
en een TNLDMarkableCustomControl. De markeringsstreepjes worden getekend op de
Canvas van het Control en worden verwijderd met Paint. Deze Paint moet in een
descender gemaakt worden, aangezien de Paint van TCustom/GraphicControl niets
doet en ik eventuele descenders niet in de weg wilde lopen.
  De markering is in en uit te schakelen met de methods Mark en UnMark. Intern
wordt een counter bijgehouden hoevaak het Control gemarkeerd is. Bij een
gelijk aantal aanroepen van UnMark wordt de markering opgeheven, of als de
property Marked op False wordt gezet.

Oorsprong:
  Ik wilde voor een planning-programma een duidelijk in het oog springend
kenmerk aan een Planning-item toevoegen om aan te geven dat die gemarkeerd was
(wat ik bijv. gebruik bij een zoekopdracht). Een border was niet duidelijk
genoeg vanwege de aanwezige gridlines, en een kleur was niet duidelijk genoeg,
want ik werkte al met meerdere kleuren voor de Planning-items.

Voordelen:
* In één applicatie, meerdere markeringen (dit kan bijvoorbeeld niet in Excel)

Nadelen:
* Indien een descender een Control plaatst, daar waar de markeringsstreepjes
  moeten gaan lopen, zijn die niet meer zichtbaar; het canvas ligt per
  definitie altijd op de onderste laag. Verplaatsen van dat Control is dan de
  enige oplossing.
* Bij vele markeringen flinke belasting van de processor vanwege het aantal
  Timers.

Bugs:
* Voor zover ik weet zijn er geen bugs.

Openstaande ideeën:
* Property MarkWidth
* Property MarkSpeed
* Property MarkColor
* Property MarkLength
* ....

Nog te onderzoeken:
* Het tekenen van de streepjes gebeurd nu nog met de Pixels-property van het
  Canvas, maar misschien is het efficienter om een custom linetype te
  definiëren en deze met LineTo/PolyLine te tekenen.
  Zie ook http://www.nldelphi.com/Forum/showthread.php?t=22368

Veel plezier...

Albert de Weerd (NGLN)
******************************************************************************)

unit NLDMarkableControl;

interface

uses
  Extctrls, Controls, Classes;

type
  TNLDMarkableGraphicControl = class(TGraphicControl)
  private
    MarkTimer: TTimer;
    MarkCounter: Integer;
    procedure OnMarkTimer(Sender: TObject);
    function GetMarked: Boolean;
  protected
    procedure SetMarked(const Value: Boolean); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Mark;
    procedure UnMark;
  published
    property Marked: Boolean read GetMarked write SetMarked default False;
  end;

  TNLDMarkableCustomControl = class(TCustomControl)
  private
    MarkTimer: TTimer;
    MarkCounter: Integer;
    procedure OnMarkTimer(Sender: TObject);
    function GetMarked: Boolean;
  protected
    procedure SetMarked(const Value: Boolean); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Mark;
    procedure UnMark;
  published
    property Marked: Boolean read GetMarked write SetMarked default False;
  end;

procedure Register;

implementation

{$R *.RES}

uses
  Graphics;

procedure Register;
begin
  RegisterComponents('NLDelphi', [TNLDMarkableGraphicControl,
    TNLDMarkableCustomControl]);
end;

{ TNLDMarkableGraphicControl }

constructor TNLDMarkableGraphicControl.Create(AOwner: TComponent);
begin
  inherited;
  MarkTimer := TTimer.Create(Self);
  MarkTimer.Enabled := False;
  MarkTimer.Interval := 40;
  MarkTimer.OnTimer := OnMarkTimer;
  MarkCounter := 0;
end;

function TNLDMarkableGraphicControl.GetMarked: Boolean;
begin
  Result := MarkCounter > 0;
end;

procedure TNLDMarkableGraphicControl.Mark;
begin
  Inc(MarkCounter);
  MarkTimer.Enabled := MarkCounter > 0;
end;

procedure TNLDMarkableGraphicControl.OnMarkTimer(Sender: TObject);
const
  MarkLength = 9; //Lengte en tussenruimte van de markeringsstreepjes
  MarkShift = 1; //Opschuifwaarde van de markeringsstreepjes
                 //bij het OnMarkTimerInterval-Event
var
  i: Integer;
  PixelColor: TColor;
begin
  for i := 0 to Width - 1 do
  begin
    if Odd((i + MarkTimer.Tag) div MarkLength) then
      PixelColor := Canvas.Brush.Color
    else
      PixelColor := clBlack;
    Canvas.Pixels[Width - i - 1, 0] := PixelColor;
    Canvas.Pixels[Width - i, 1] := PixelColor;
    Canvas.Pixels[i + 1, Height - 1] := PixelColor;
    Canvas.Pixels[i, Height - 2] := PixelColor;
  end;
  for i := 0 to Height - 1 do
  begin
    if Odd((i + MarkTimer.Tag) div MarkLength) then
      PixelColor := Canvas.Brush.Color
    else
      PixelColor := clBlack;
    Canvas.Pixels[0, i] := PixelColor;
    Canvas.Pixels[1, i - 1] := PixelColor;
    Canvas.Pixels[Width - 1, Height - i - 1] := PixelColor;
    Canvas.Pixels[Width - 2, Height - i] := PixelColor;
  end;
  //MarkTimer.Tag = aantal keren dat de markeringsstreepjes zijn opgeschoven
  MarkTimer.Tag := MarkTimer.Tag + MarkShift;
end;

procedure TNLDMarkableGraphicControl.SetMarked(const Value: Boolean);
begin
  if Value <> GetMarked then
    if Value then
      Mark
    else
    begin
      MarkCounter := 0;
      UnMark;
    end;
end;

procedure TNLDMarkableGraphicControl.UnMark;
begin
  if MarkCounter > 0 then
    Dec(MarkCounter);
  MarkTimer.Enabled := MarkCounter > 0;
  if MarkCounter = 0 then
    Paint;
end;

{ TMarkableCustomControl }

constructor TNLDMarkableCustomControl.Create(AOwner: TComponent);
begin
  inherited;
  MarkTimer := TTimer.Create(Self);
  MarkTimer.Enabled := False;
  MarkTimer.Interval := 40;
  MarkTimer.OnTimer := OnMarkTimer;
  MarkCounter := 0;
end;

function TNLDMarkableCustomControl.GetMarked: Boolean;
begin
  Result := MarkCounter > 0;
end;

procedure TNLDMarkableCustomControl.Mark;
begin
  Inc(MarkCounter);
  MarkTimer.Enabled := MarkCounter > 0;
end;

procedure TNLDMarkableCustomControl.OnMarkTimer(Sender: TObject);
const
  MarkLength = 9;
  MarkShift = 1;
var
  i: Integer;
  PixelColor: TColor;
begin
  for i := 0 to Width - 1 do
  begin
    if Odd((i + MarkTimer.Tag) div MarkLength) then
      PixelColor := Canvas.Brush.Color
    else
      PixelColor := clBlack;
    Canvas.Pixels[Width - i - 1, 0] := PixelColor;
    Canvas.Pixels[Width - i, 1] := PixelColor;
    Canvas.Pixels[i + 1, Height - 1] := PixelColor;
    Canvas.Pixels[i, Height - 2] := PixelColor;
  end;
  for i := 0 to Height - 1 do
  begin
    if Odd((i + MarkTimer.Tag) div MarkLength) then
      PixelColor := Canvas.Brush.Color
    else
      PixelColor := clBlack;
    Canvas.Pixels[0, i] := PixelColor;
    Canvas.Pixels[1, i - 1] := PixelColor;
    Canvas.Pixels[Width - 1, Height - i - 1] := PixelColor;
    Canvas.Pixels[Width - 2, Height - i] := PixelColor;
  end;
  MarkTimer.Tag := MarkTimer.Tag + MarkShift;
end;

procedure TNLDMarkableCustomControl.SetMarked(const Value: Boolean);
begin
  if Value <> GetMarked then
    if Value then
      Mark
    else
    begin
      MarkCounter := 0;
      UnMark;
    end;
end;

procedure TNLDMarkableCustomControl.UnMark;
begin
  if MarkCounter > 0 then
    Dec(MarkCounter);
  MarkTimer.Enabled := MarkCounter > 0;
  if MarkCounter = 0 then
    Paint;
end;

end.
