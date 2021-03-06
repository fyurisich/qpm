/*
 * $Id$
 */

/*
 *    QPM - QAC based Project Manager
 *
 *    Copyright 2011-2020 Fernando Yurisich <fernando.yurisich@gmail.com>
 *    https://teamqpm.github.io/
 *
 *    Based on QAC - Project Manager for (x)Harbour
 *    Copyright 2006-2011 Carozo de Quilmes <CarozoDeQuilmes@gmail.com>
 *    http://www.CarozoDeQuilmes.com.ar
 *
 *    This program is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
/*
 * This file was borrowed from Harbour MiniGUI Extended Edition 2.0.3
*/

#include "hbclass.ch"

#ifndef __XHARBOUR__
   #xcommand TRY                => bError := errorBlock( {|oError| break( oError ) } ) ;;
                                   BEGIN SEQUENCE
   #xcommand CATCH [<!oError!>] => errorBlock( bError ) ;;
                                   RECOVER [USING <oError>] <-oError-> ;;
                                   errorBlock( bError )
#endif

CLASS TActiveX
   DATA oOle
   DATA hWnd
   DATA cWindowName
   DATA cProgId
   DATA nRow
   DATA nCol
   DATA nWidth
   DATA nHeight
   DATA nOldWinWidth
   DATA nOldWinHeight
   DATA bHide INIT .F.
   METHOD New( cWindowName, cProgId , nRow , nCol , nWidth , nHeight )
   METHOD Load()
   METHOD ReSize( nRow , nCol , nWidth , nHeight )
   METHOD Hide()
   METHOD Show()
   METHOD Release()
   METHOD Refresh()
   METHOD Adjust()
   METHOD GetRow()
   METHOD GetCol()
   METHOD GetWidth()
   METHOD GetHeight()
ENDCLASS

METHOD New( cWindowName , cProgId , nRow , nCol , nWidth , nHeight ) CLASS TActiveX
   if( empty( nRow )    , nRow    := 0 , )
   if( empty( nCol )    , nCol    := 0 , )
   if( empty( nWidth )  , nWidth  := GetProperty( cWindowName , "width" ) , )
   if( empty( nHeight ) , nHeight := GetProperty( cWindowName , "Height" ) , )
   ::nRow := nRow
   ::nCol := nCol
   ::nWidth := nWidth
   ::nHeight := nHeight
   ::cWindowName := cWindowName
   ::cProgId := cProgId
   ::nOldWinWidth := GetProperty( cWindowName , "width" )
   ::nOldWinHeight := GetProperty( cWindowName , "Height" )
Return Self

METHOD Load() CLASS TActiveX
   local oError, bError
   local nHandle := GetFormHandle(::cWindowName)
   local xObjeto
   AtlAxWinInit()
   ::hWnd := CreateWindowEx( nHandle, ::cProgId )
   MoveWindow( ::hWnd , ::nCol , ::nRow , ::nWidth , ::nHeight , .t. )
   xObjeto := AtlAxGetDisp( ::hWnd )
   TRY
      ::oOle := CreateObject( xObjeto )
   CATCH oError
      MsgInfo( oError:description, nil, nil, .F. )
   END
RETURN ::oOle

METHOD ReSize( nRow , nCol , nWidth , nHeight ) CLASS TActiveX
   if !::bHide
      MoveWindow( ::hWnd , nCol , nRow , nWidth , nHeight , .t. )
   endif
   ::nRow := nRow
   ::nCol := nCol
   ::nWidth := nWidth
   ::nHeight := nHeight
   ::nOldWinWidth := GetProperty( ::cWindowName , "width" )
   ::nOldWinHeight := GetProperty( ::cWindowName , "Height" )
RETURN .T.

METHOD Adjust() CLASS TActiveX
   Local nAuxRight , nAuxBottom
   nAuxRight := ( ::nOldWinWidth - ( ::nWidth + ::nCol ) )
   nAuxBottom := ( ::nOldWinHeight - ( ::nHeight + ::nRow ) )
   MoveWindow( ::hWnd , ::nCol , ::nRow , GetProperty( ::cWindowName , "width" ) - ::nCol - nAuxRight , GetProperty( ::cWindowName , "height" ) - ::nRow - nAuxBottom , .t. )
   ::nWidth := GetProperty( ::cWindowName , "width" ) - ::nCol - nAuxRight
   ::nHeight := GetProperty( ::cWindowName , "height" ) - ::nRow - nAuxBottom
   ::nOldWinWidth := GetProperty( ::cWindowName , "width" )
   ::nOldWinHeight := GetProperty( ::cWindowName , "Height" )
RETURN .T.

METHOD GetRow() CLASS TActiveX
RETURN ::nRow

METHOD GetCol() CLASS TActiveX
RETURN ::nCol

METHOD GetWidth() CLASS TActiveX
RETURN ::nWidth

METHOD GetHeight() CLASS TActiveX
RETURN ::nHeight

METHOD Hide() CLASS TActiveX
   MoveWindow( ::hWnd , 0 , 0 , 0 , 0 , .t. )
   ::bHide := .T.
RETURN .T.

METHOD Show() CLASS TActiveX
   MoveWindow( ::hWnd , ::nCol , ::nRow , ::nWidth , ::nHeight , .t. )
   ::bHide := .F.
RETURN .T.

METHOD Release() CLASS TActiveX
   DestroyWindow( ::hWnd )
   AtlAxWinEnd()
RETURN .T.

METHOD Refresh() CLASS TActiveX
   ::Hide()
   ::Show()
RETURN .T.


#pragma BEGINDUMP

#include <windows.h>
#include <commctrl.h>
#include <hbapi.h>
#include "qpm.h"

typedef HRESULT ( WINAPI *LPAtlAxWinInit )    ( void );
typedef HRESULT ( WINAPI *LPAtlAxGetControl ) ( HWND hwnd, IUnknown** unk );

HMODULE hAtl = NULL;
LPAtlAxWinInit    AtlAxWinInit;
LPAtlAxGetControl AtlAxGetControl;

static void _Ax_Init( void )
{
   if( ! hAtl )
   {
      hAtl = LoadLibrary( "Atl.Dll" );
      AtlAxWinInit    = ( LPAtlAxWinInit )    GetProcAddress( hAtl, "AtlAxWinInit" );
      AtlAxGetControl = ( LPAtlAxGetControl ) GetProcAddress( hAtl, "AtlAxGetControl" );
      ( AtlAxWinInit )();
   }
}

HB_FUNC( ATLAXWININIT )
{
   _Ax_Init();
}

HB_FUNC( ATLAXWINEND )
{
   if( hAtl )
      FreeLibrary( hAtl );
}

HB_FUNC( ATLAXGETDISP ) // hWnd -> pDisp
{
   IUnknown *pUnk;
   IDispatch *pDisp;
   _Ax_Init();
   AtlAxGetControl( (HWND) HB_PARNL( 1 ), &pUnk );
   pUnk->lpVtbl->QueryInterface( pUnk, &IID_IDispatch, ( void ** ) &pDisp );
   HB_RETNL( (LONG_PTR) pDisp );
}

HB_FUNC_STATIC( CREATEWINDOWEX ) // hWnd, cProgId -> hActiveXWnd
{
   HWND hControl;
   hControl = CreateWindowEx( 0, "AtlAxWin", hb_parc( 2 ),
              WS_VISIBLE|WS_CHILD, 0, 0, 0, 0, (HWND) HB_PARNL( 1 ), 0, 0, NULL );
   HB_RETNL( (LONG_PTR) hControl );
}

#pragma ENDDUMP
