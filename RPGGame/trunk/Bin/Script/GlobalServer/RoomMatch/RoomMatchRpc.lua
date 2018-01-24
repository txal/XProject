---------------服务器内部----------------
function Srv2Srv.OnCreateRoomReq(nSrc, nSession, nRoomID, nDeskType)
	goRoomMgr:OnCreateRoom(nRoomID, nDeskType, nSrc)
end

function Srv2Srv.OnDismissRoomReq(nSrc, nSession, nRoomID, nDeskType)
	goRoomMgr:OnDismissRoom(nRoomID, nDeskType)
end

function Srv2Srv.OnPlayerEnterReq(nSrc, nSession, nRoomID, nDeskType, nCharID)
	goRoomMgr:OnPlayerEnter(nRoomID, nDeskType, nCharID)
end

function Srv2Srv.OnPlayerLeaveReq(nSrc, nSession, nRoomID, nDeskType, nCharID)
	goRoomMgr:OnPlayerLeave(nRoomID, nDeskType, nCharID)
end

function Srv2Srv.FreeRoomMatchReq(nSrc, nSession, nDeskType, nCharID)
	goRoomMgr:FreeRoomMatch(nDeskType, nCharID, nSrc)
end
