{
Omschrijving:
NLDMarkableCustomControl toont m.b.v. een Timer-event een 'wandelend' selectiekader rond een TCustomControl
van 2 pixels breed, ongeveer gelijk aan het markeringskader van MS Excel. In een andere vorm wordt dit ook wel
Marching Ants genoemd. Zie ook http://www.nldelphi.com/Forum/showthread.php?threadid=16633
De markeringsstreepjes worden getekend op de Canvas van het CustomControl en worden verwijderd met Paint.
Deze Paint moet in een descender gemaakt worden, aangezien de Paint van TCustomControl niets doet en ik
eventuele descenders niet in de weg wilde lopen.

Oorsprong:
Ik wilde voor een planning-programma een duidelijk in het oog springend kenmerk aan een Planning-item toevoegen
om aan te geven dat die gemarkeerd was (wat ik bijv. gebruik bij een zoekopdracht). Een border was niet duidelijk
genoeg vanwege de aanwezige gridlines, en een kleur was niet duidelijk genoeg, want ik werkte al met meerdere
 kleuren voor de Planning-items. Zie ook onderstaand plaatje voor een voorbeeld van hoe het nu werkt.

Voordelen:
* In één applicatie, meerdere markeringen! (Dit kan bijvoorbeeld niet in Excel)

Nadelen:
* Indien een descender een Control plaatst, daar waar de markeringsstreepjes moeten gaan lopen, zijn die niet
  meer zichtbaar; het canvas ligt per definitie altijd op de onderste laag. Een evt. oplossing is de Anchors
  in te stellen van de Control.
* Bij vele markeringen flinke belasting van de processor vanwege het aantal Timers

Bugs:
Voor zover ik weet zijn er geen bugs.

Openstaande ideeën:
* Property MarkWidth toevoegen om de dikte van de markeringsstreepjes te kunnen variëren
* Property MarkSpeed toevoegen om de interval van de Timer te kunnen variëren
* Property MarkColor toevoegen....
* ....

Graag verneem ik commentaar over bovenstaand verhaal, onderstaand verhaal, de manier, de werking, etc... ga je gang.

Ik heb jaren geleden wel eens wat hobbiematig geprogrammeerd met Delphi, maar was laatst toch wanhopig op zoek
naar een planningprogramma voor de zaak. Nu kon ik geen geschikt bestaand programma vinden en dus heb ik de draad
weer opgepakt met Delphi. Ben inmiddels natuurlijk behoorlijk trots op het resultaat, maar weet zeker dat ik nog
niet het onderste uit de kan heb weten te halen, dus alle opmerkingen waar ik van kan leren zijn welkom.

Groeten...
}

unit NLDMarkableCustomControl;

interface

uses Extctrls, Graphics, Controls, Classes;

type
  TNLDMarkableCustomControl = class(TCustomControl)
    private
      FMarkTimer: TTimer;
      FMarkLength: Byte;  // Lengte van een markeringsstreepje
      FMarkShift: Byte;  // Opschuifwaarde van de markeringsstreepjes bij het OnMarkTimerInterval-Event
      FMarked: Boolean;
      procedure SetMarked(const Value: Boolean);
      procedure OnMarkTimerInterval(Sender: TObject);
    protected
      property MarkLength: Byte write FMarkLength;
      property MarkShift: Byte write FMarkShift;
    public
      constructor Create(AOwner: TComponent); override;
      property Marked: Boolean read FMarked write SetMarked;
  end;

implementation

{ TNLDMarkableCustomControl }

constructor TNLDMarkableCustomControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMarkTimer := TTimer.Create(Self);
  FMarkTimer.Enabled := False;
  FMarkTimer.Interval := 100;
  FMarkTimer.OnTimer := OnMarkTimerInterval;
  FMarkLength := 9;  // De standaardwaarde, is met de property MarkLength runtime in te stellen
  FMarkShift := 2;  // De standaardwaarde, is met de property MarkShift runtime in te stellen
end;

procedure TNLDMarkableCustomControl.OnMarkTimerInterval(Sender: TObject);
var
  X, Y: Integer;  // Dit kan ook met slechts één variabele, maar voor de leesbaarheid gesplitst
  PixelColor: TColor;
 // MarchCount: LongInt;  // Aantal keren dat de markeringsstreepjes zijn opgeschoven,
                          // hiervoor wordt FMarkTimer.Tag gebruikt, is toch al aanwezig, dus waarom niet gebruiken
begin
  for X := 0 to Width -1 do begin
    if Odd(Trunc((X + FMarkTimer.Tag) / FMarkLength)) then PixelColor := Color else PixelColor := clBlack;
    Canvas.Pixels[Width - X - 1, 0] := PixelColor;
    Canvas.Pixels[Width - X, 1] := PixelColor;
    Canvas.Pixels[X, Height - 1] := PixelColor;
    Canvas.Pixels[X - 1, Height - 2] := PixelColor;
  end;
  for Y := 0 to Height -1 do begin
    if Odd(Trunc((Y + FMarkTimer.Tag) / FMarkLength)) then PixelColor := Color else PixelColor := clBlack;
    Canvas.Pixels[0, Y] := PixelColor;
    Canvas.Pixels[1, Y - 1] := PixelColor;
    Canvas.Pixels[Width - 1, Height - Y - 1] := PixelColor;
    Canvas.Pixels[Width - 2, Height - Y] := PixelColor;
  end;
//  if FMarkTimer.Tag >= MaxLongInt then FMarkTimer.Tag := 0;  // Het blijkt na testen dat dit niet hoeft (vreemd!)
  FMarkTimer.Tag := FMarkTimer.Tag + FMarkShift;  // Inc werkt hier helaas niet, want Tag is een property
end;

procedure TNLDMarkableCustomControl.SetMarked(const Value: Boolean);
begin
  if Value <> FMarked then begin
    FMarked := Value;
    FMarkTimer.Enabled := FMarked;
    if not FMarked then Paint;  // Om de markeringsstreepjes weer weg te halen; aan te maken in een descender!!
  end;
end;

end.
