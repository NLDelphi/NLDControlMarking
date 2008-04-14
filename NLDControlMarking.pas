unit NLDControlMarking;

interface

uses
  Classes, Windows, Graphics, ExtCtrls, Controls;

type
  TMarkDirection = (mdClockwise, mdCounterclockwise);

  TMarkBounds = (mbClient, mbWindow);

const
  DefMarkBounds = mbWindow;
  DefMarkColor = clBlack;
  DefMarkDirection = mdClockwise;
  DefMarkInterval = 40;
  DefMarkLength = 9;
  DefMarkShift = 1;
  DefMarkWidth = 2;
  DefSpaceColor = clDefault;

type
  TCustomControlMarker = class(TComponent)
  private
    FControls: TList;
    FMarkBounds: TMarkBounds;
    FMarkBrush: LOGBRUSH;
    FMarkColor: TColor;
    FMarkDirection: TMarkDirection;
    FMarkLength: Byte;
    FMarkPen: HPEN;
    FMarkPosition: Word;
    FMarkShift: Byte;
    FMarkTimer: TTimer;
    FMarkWidth: Byte;
    FPenStyle: array[0..1] of Integer;
    FSpaceBrush: LOGBRUSH;
    FSpaceColor: TColor;
    FSpacePen: HPEN;
    function GetControlCount: Integer;
    function GetMarkInterval: Cardinal;
    procedure MarkTimer(Sender: TObject);
    procedure PaintControls;
    procedure ResetPens(const AltSpaceColor: TColor = clDefault);
    procedure SetMarkColor(const Value: TColor);
    procedure SetMarkInterval(const Value: Cardinal);
    procedure SetMarkLength(const Value: Byte);
    procedure SetMarkWidth(const Value: Byte);
    procedure SetSpaceColor(const Value: TColor);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation);
      override;
    property MarkBounds: TMarkBounds read FMarkBounds write FMarkBounds
      default DefMarkBounds;
    property MarkColor: TColor read FMarkColor write SetMarkColor
      default DefMarkColor;
    property MarkDirection: TMarkDirection read FMarkDirection
      write FMarkDirection default DefMarkDirection;
    property MarkInterval: Cardinal read GetMarkInterval write SetMarkInterval
      default DefMarkInterval;
    property MarkLength: Byte read FMarkLength write SetMarkLength
      default DefMarkLength;
    property MarkShift: Byte read FMarkShift write FMarkShift
      default DefMarkShift;
    property MarkWidth: Byte read FMarkWidth write SetMarkWidth
      default DefMarkWidth;
    property SpaceColor: TColor read FSpaceColor write SetSpaceColor
      default DefSpaceColor;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure MarkControl(AControl: TControl);
    procedure UnmarkControl(AControl: TControl);
    procedure UnmarkControls;
    property ControlCount: Integer read GetControlCount;
  end;

  TNLDControlMarker = class(TCustomControlMarker)
  published
    property MarkBounds;
    property MarkColor;
    property MarkDirection;
    property MarkInterval;
    property MarkLength;
    property MarkShift;
    property MarkWidth;
    property SpaceColor;
  end;

  TMarkableGraphicControl = class(TGraphicControl)
  private
    FMarkCounter: Integer;
    function GetMarked: Boolean;
    procedure SetMarked(const Value: Boolean);
  protected
    function GetMarker: TCustomControlMarker; virtual;
  public
    procedure Mark; virtual;
    procedure UnMark; virtual;
    property Marked: Boolean read GetMarked write SetMarked default False;
  end;

  TMarkableCustomControl = class(TCustomControl)
  private
    FMarkCounter: Integer;
    function GetMarked: Boolean;
    procedure SetMarked(const Value: Boolean);
  protected
    function GetMarker: TCustomControlMarker; virtual;
  public
    procedure Mark; virtual;
    procedure UnMark; virtual;
    property Marked: Boolean read GetMarked write SetMarked default False;
  end;

function DefControlMarker: TNLDControlMarker;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('NLDelphi', [TNLDControlMarker]);
end;

var
  FControlMarker: TNLDControlMarker;

function DefControlMarker: TNLDControlMarker;
begin
  if FControlMarker = nil then
    FControlMarker := TNLDControlMarker.Create(nil);
  Result := FControlMarker;
end;

type
  TPublicControl = class(TControl);
  TPublicGraphicControl = class(TGraphicControl);
  TPublicCustomControl = class(TCustomControl);

{ TCustomControlMarker }

constructor TCustomControlMarker.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FControls := TList.Create;
  FMarkBounds := DefMarkBounds;
  FMarkColor := DefMarkColor;
  FMarkDirection := DefMarkDirection;
  FMarkShift := DefMarkShift;
  FMarkWidth := DefMarkWidth;
  FMarkTimer := TTimer.Create(nil);
  FMarkTimer.Enabled := False;
  FMarkTimer.Interval := DefMarkInterval;
  FMarkTimer.OnTimer := MarkTimer;
  FMarkBrush.lbStyle := BS_SOLID;
  FSpaceBrush.lbStyle := BS_SOLID;
  FSpaceColor := DefSpaceColor;
  SetMarkLength(DefMarkLength);
  ResetPens;
end;

destructor TCustomControlMarker.Destroy;
begin
  FMarkTimer.Enabled := False;
  FControls.Free;
  FMarkTimer.Free;
  inherited Destroy;
end;

function TCustomControlMarker.GetControlCount: Integer;
begin
  Result := FControls.Count;
end;

function TCustomControlMarker.GetMarkInterval: Cardinal;
begin
  Result := FMarkTimer.Interval;
end;

procedure TCustomControlMarker.MarkControl(AControl: TControl);
begin
  if AControl is TMarkableGraphicControl then
    Inc(TMarkableGraphicControl(AControl).FMarkCounter)
  else if AControl is TMarkableCustomControl then
    Inc(TMarkableCustomControl(AControl).FMarkCounter);
  if FControls.IndexOf(AControl) < 0 then
  begin
    FControls.Add(AControl);
    FreeNotification(AControl);
  end;
  if FControls.Count = 1 then
    FMarkTimer.Enabled := True;
end;

procedure TCustomControlMarker.MarkTimer(Sender: TObject);
begin
  PaintControls;
  Inc(FMarkPosition, FMarkShift);
  if FMarkPosition >= (2 * FMarkLength) then
    FMarkPosition := 0;
end;

procedure TCustomControlMarker.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  if Operation = opRemove then
    FControls.Remove(AComponent);
  inherited Notification(AComponent, Operation);
end;

procedure TCustomControlMarker.PaintControls;
var
  i: Integer;
  DC: HDC;
  Rect: TRect;
  Points: array[0..4] of TPoint;
begin
  for i := 0 to FControls.Count - 1 do
  begin
    DC := 0;
    if TControl(FControls[i]) is TGraphicControl then
      DC := TPublicGraphicControl(FControls[i]).Canvas.Handle
    else if TControl(FControls[i]) is TCustomControl then
      DC := TPublicCustomControl(FControls[i]).Canvas.Handle
    else if TControl(FControls[i]) is TWinControl then
      if FMarkBounds = mbClient then
        DC := GetDC(TWinControl(FControls[i]).Handle)
      else
        DC := GetWindowDC(TWinControl(FControls[i]).Handle);
    if DC <> 0 then
      try
        if FMarkBounds = mbClient then
          Rect := TControl(FControls[i]).ClientRect
        else
          with TControl(FControls[i]) do
            Rect := Classes.Rect(0, 0, Width, Height);
        InflateRect(Rect, -FMarkWidth div 2, -FMarkWidth div 2);
        if FSpaceColor = clDefault then
          ResetPens(TPublicControl(FControls[i]).Color);
        case MarkDirection of
          mdClockwise:
            with Rect do
            begin
              SelectObject(DC, FSpacePen);
              Points[0] := Point(Left, -FMarkPosition + FMarkLength);
              Points[1] := Point(Left, Bottom);
              Points[2] := BottomRight;
              Points[3] := Point(Right, Top);
              Points[4] := Point(FMarkWidth, Top);
              Polyline(DC, Points[0], 5);
              SelectObject(DC, FMarkPen);
              Points[0] := Point(Left, -FMarkPosition);
              Polyline(DC, Points[0], 5);
            end;
          mdCounterclockwise:
            with Rect do
            begin
              SelectObject(DC, FSpacePen);
              Points[0] := Point(-FMarkPosition + FMarkLength, Top);
              Points[1] := Point(Right, Top);
              Points[2] := BottomRight;
              Points[3] := Point(Left, Bottom);
              Points[4] := Point(Left, FMarkWidth);
              Polyline(DC, Points[0], 5);
              SelectObject(DC, FMarkPen);
              Points[0] := Point(-FMarkPosition, Top);
              Polyline(DC, Points[0], 5);
            end;
        end;
      finally
        if TControl(FControls[i]) is TWinControl then
          ReleaseDC(TWinControl(FControls[i]).Handle, DC);
      end;
  end;
end;

procedure TCustomControlMarker.ResetPens(
  const AltSpaceColor: TColor = clDefault);
begin
  if AltSpaceColor = clDefault then
  begin
    FMarkBrush.lbColor := ColorToRGB(FMarkColor);
    DeleteObject(FMarkPen);
    FMarkPen := ExtCreatePen(PS_GEOMETRIC or PS_USERSTYLE, FMarkWidth,
      FMarkBrush, 2, @FPenStyle);
    FSpaceBrush.lbColor := ColorToRGB(FSpaceColor);
    DeleteObject(FSpacePen);
    FSpacePen := ExtCreatePen(PS_GEOMETRIC or PS_USERSTYLE, FMarkWidth,
      FSpaceBrush, 2, @FPenStyle);
  end else if Cardinal(ColorToRGB(AltSpaceColor)) <> FSpaceBrush.lbColor then
  begin
    FSpaceBrush.lbColor := ColorToRGB(AltSpaceColor);
    DeleteObject(FSpacePen);
    FSpacePen := ExtCreatePen(PS_GEOMETRIC or PS_USERSTYLE, FMarkWidth,
      FSpaceBrush, 2, @FPenStyle);
  end;
end;

procedure TCustomControlMarker.SetMarkColor(const Value: TColor);
begin
  if FMarkColor <> Value then
  begin
    FMarkColor := Value;
    ResetPens;
  end;
end;

procedure TCustomControlMarker.SetMarkInterval(const Value: Cardinal);
begin
  FMarkTimer.Interval := Value;
end;

procedure TCustomControlMarker.SetMarkLength(const Value: Byte);
begin
  if FMarkLength <> Value then
  begin
    FMarkLength := Value;
    FPenStyle[0] := FMarkLength;
    FPenStyle[1] := FMarkLength;
    ResetPens;
  end;
end;

procedure TCustomControlMarker.SetMarkWidth(const Value: Byte);
begin
  if FMarkWidth <> Value then
  begin
    FMarkWidth := Value;
    ResetPens;
  end;
end;

procedure TCustomControlMarker.SetSpaceColor(const Value: TColor);
begin
  if FSpaceColor <> Value then
  begin
    FSpaceColor := Value;
    ResetPens;
  end;
end;

procedure TCustomControlMarker.UnmarkControl(AControl: TControl);

  procedure RemoveControl;
  begin
    FControls.Remove(AControl);
    AControl.Repaint;
    if AControl is TWinControl then
      if FMarkBounds = mbWindow then
        RedrawWindow(TWinControl(AControl).Handle, nil, 0,
          RDW_FRAME or RDW_INVALIDATE or RDW_NOCHILDREN);
    RemoveFreeNotification(AControl);
  end;

begin
  if FControls.IndexOf(AControl) > -1 then
  begin
    if AControl is TMarkableGraphicControl then
    begin
      Dec(TMarkableGraphicControl(AControl).FMarkCounter);
      if TMarkableGraphicControl(AControl).FMarkCounter = 0 then
        RemoveControl;
    end else if AControl is TMarkableCustomControl then
    begin
      Dec(TMarkableCustomControl(AControl).FMarkCounter);
      if TMarkableCustomControl(AControl).FMarkCounter = 0 then
        RemoveControl;
    end else
      RemoveControl;
  end;
  if FControls.Count = 0 then
    FMarkTimer.Enabled := False;
end;

procedure TCustomControlMarker.UnmarkControls;
var
  i: Integer;
begin
  for i := FControls.Count - 1 downto 0 do
    UnmarkControl(FControls[i]);
end;

{ TMarkableGraphicControl }

function TMarkableGraphicControl.GetMarked: Boolean;
begin
  Result := FMarkCounter > 0;
end;

function TMarkableGraphicControl.GetMarker: TCustomControlMarker;
begin
  Result := DefControlMarker;
end;

procedure TMarkableGraphicControl.Mark;
begin
  GetMarker.MarkControl(Self);
end;

procedure TMarkableGraphicControl.SetMarked(const Value: Boolean);
begin
  if GetMarked <> Value then
    if Value then
      Mark
    else
    begin
      FMarkCounter := 1;
      UnMark;
    end;
end;

procedure TMarkableGraphicControl.UnMark;
begin
  GetMarker.UnmarkControl(Self);
end;

{ TMarkableCustomControl }

function TMarkableCustomControl.GetMarked: Boolean;
begin
  Result := FMarkCounter > 0;
end;

function TMarkableCustomControl.GetMarker: TCustomControlMarker;
begin
  Result := DefControlMarker;
end;

procedure TMarkableCustomControl.Mark;
begin
  GetMarker.MarkControl(Self);
end;

procedure TMarkableCustomControl.SetMarked(const Value: Boolean);
begin
  if GetMarked <> Value then
    if Value then
      Mark
    else
    begin
      FMarkCounter := 1;
      UnMark;
    end;
end;

procedure TMarkableCustomControl.UnMark;
begin
  GetMarker.UnmarkControl(Self);
end;

initialization

finalization
  if FControlMarker <> nil then
    FControlMarker.Free;

end.
