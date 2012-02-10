transporter "translateScriptNameTransporter"{
	consts{
		//comboLights
		LIGHTS_AUTO = 0;
		LIGHTS_ON   = 1;
		LIGHTS_OFF  = 2;

		//comboTransporterMode
		TRANSPORTER_MODE_AUTO   = 0;
		TRANSPORTER_MODE_MANUAL = 1;
	}

	enum comboLights{
		"translateCommandStateLightsAUTO", //LIGHTS_AUTO
		"translateCommandStateLightsON",   //LIGHTS_ON
		"translateCommandStateLightsOFF",  //LIGHTS_OFF
	multi:
		"translateCommandStateLightsMode"
	}

	enum comboTransporterMode{
		"translateCommandTransporterModeAuto",   //TRANSPORTER_MODE_AUTO
		"translateCommandTransporterModeManual", //TRANSPORTER_MODE_MANUAL
	multi:
		"translateCommandTransporterMode"
	}

	int m_nState;
	int m_nGetUnitFirstPosX;
	int m_nGetUnitFirstPosY;
	int m_nGetUnitFirstPosZ;
	int m_nPutPosX;
	int m_nPutPosY;
	int m_nPutPosZ;
	int m_nMoveToX;
	int m_nMoveToY;
	int m_nMoveToZ;
	int m_nAutoGetPointX;
	int m_nAutoGetPointY;
	int m_nAutoGetPointZ;
	int m_bValidAutoGetPoint;
	int m_nAutoPutPointX;
	int m_nAutoPutPointY;
	int m_nAutoPutPointZ;
	int m_bValidAutoPutPoint;
	unit m_uUnitToTransport;
	int  m_nLandCounter;

	function int Land()	{
		if(!IsOnGround()){
			m_nMoveToX=GetLocationX();
			m_nMoveToY=GetLocationY();
			m_nMoveToZ=GetLocationZ();
			if(!IsFreePoint(m_nMoveToX, m_nMoveToY, m_nMoveToZ)){
				if(Rand(2)){
					m_nMoveToX=m_nMoveToX+Rand(m_nLandCounter)+1;
				}else{
					m_nMoveToX=m_nMoveToX-Rand(m_nLandCounter)+1;
				}
				if(Rand(2)){
					m_nMoveToY=m_nMoveToY+Rand(m_nLandCounter)+1;
				}else{
					m_nMoveToY=m_nMoveToY-Rand(m_nLandCounter)+1;
				}
				++m_nLandCounter;
				if(IsFreePoint(m_nMoveToX, m_nMoveToY, m_nMoveToZ)){
					CallMoveAndLandToPoint(m_nMoveToX, m_nMoveToY, m_nMoveToZ);
				}else{
					CallMoveLowToPoint(m_nMoveToX, m_nMoveToY, m_nMoveToZ);
				}
			}else{
				CallMoveAndLandToPoint(m_nMoveToX, m_nMoveToY, m_nMoveToZ);
			}
			return true;
		}
		return false;
	}

	function int SetUnitToTransport(unit uUnit){
		m_uUnitToTransport=uUnit;
		SetTargetObject(uUnit);
		return true;
	}

	function int CalcMoveToPutGetPointCoords(int nX, int nY, int nZ){
		int nPosX;
		int nPosY;
		int nPosZ;
		int nMinDist;
		int nDist;
		if(IsHelicopter()){
			m_nMoveToX=nX;
			m_nMoveToY=nY;
			m_nMoveToZ=nZ;
		}else{
			nPosX=GetLocationX();
			nPosY=GetLocationY();
			nPosZ=GetLocationZ();
			m_nMoveToX=nX;
			m_nMoveToY=nY;
			m_nMoveToZ=nZ;
			nMinDist=1000;
			if(IsFreePoint(nX, nY-1, nZ) || ((nX==nPosX) && ((nY-1)==nPosY) && (nZ==nPosZ))){
				m_nMoveToX=nX;
				m_nMoveToY=nY-1;
				m_nMoveToZ=nZ;
				nMinDist=Distance(nPosX, nPosY, m_nMoveToX, m_nMoveToY);
			}
			if(
				(IsFreePoint(nX+1, nY, nZ) || (((nX+1)==nPosX) && (nY==nPosY) && (nZ==nPosZ)))
				&&
				(Distance(nPosX, nPosY, nX+1, nY) < nMinDist)
			){
				m_nMoveToX=nX+1;
				m_nMoveToY=nY;
				m_nMoveToZ=nZ;
				nMinDist=Distance(nPosX, nPosY, m_nMoveToX, m_nMoveToY);
			}
			if(
				(IsFreePoint(nX, nY+1, nZ) || ((nX==nPosX) && ((nY+1)==nPosY) && (nZ==nPosZ)))
				&&
				(Distance(nPosX, nPosY, nX, nY+1) < nMinDist)
			){
				m_nMoveToX=nX;
				m_nMoveToY=nY+1;
				m_nMoveToZ=nZ;
				nMinDist=Distance(nPosX, nPosY, m_nMoveToX, m_nMoveToY);
			}
			if(
				(IsFreePoint(nX-1, nY, nZ) || (((nX-1)==nPosX) && (nY==nPosY) && (nZ==nPosZ)))
				&&
				(Distance(nPosX, nPosY, nX-1, nY) < nMinDist)
			){
				m_nMoveToX=nX-1;
				m_nMoveToY=nY;
				m_nMoveToZ=nZ;
			}
		}
		return true;
	}

	state Initialize;
	state Nothing;
	state StartMoving;
	state Moving;
	state StartLanding;
	state Landing;
	state Froozen;
	state MovingToGetUnit;
	state GettingUnit;
	state MovingToPutUnit;
	state PuttingUnit;
	state MovingToDropUnit;
	state DroppingUnit;

	state Initialize{
		return Nothing;
	}

	state Nothing{
		unit uUnit;
		if(comboTransporterMode==TRANSPORTER_MODE_AUTO){
			if(HaveUnitOnHook()){
				if(m_bValidAutoPutPoint){
					//odstawic unit do put point
					if(FindFreePlaceToPutUnitFromHook(m_nAutoPutPointX, m_nAutoPutPointY, m_nAutoPutPointZ, 6)){
						m_nPutPosX=GetFoundFreePlaceToPutUnitX();
						m_nPutPosY=GetFoundFreePlaceToPutUnitY();
						m_nPutPosZ=GetFoundFreePlaceToPutUnitZ();
						CalcMoveToPutGetPointCoords(m_nPutPosX, m_nPutPosY, m_nPutPosZ);
						CallMoveToPoint(m_nMoveToX, m_nMoveToY, m_nMoveToZ);
						return MovingToPutUnit;
					}
				}
			}else{
				if(m_bValidAutoGetPoint){
					//wziac unit z okolic get point jesli jest jakis
					BuildTargetsArray(findTargetWaterUnit|findTargetNormalUnit, findAllyUnit|findOurUnit, findDestinationAnyUnit, m_nAutoGetPointX, m_nAutoGetPointY, m_nAutoGetPointZ, 4);
					SortFoundTargetsArray();
					if(StartEnumTargetsArray()){
						do{
							uUnit=GetNextTarget();
							if(
								(uUnit!=null) && uUnit.CanBeTransported()
								&&
								(Distance(m_nAutoGetPointX, m_nAutoGetPointY, uUnit.GetLocationX(), uUnit.GetLocationY()) <= 4)
								&&
								!uUnit.IsMoving()
							){
								EndEnumTargetsArray();
								SetUnitToTransport(uUnit);
								m_nGetUnitFirstPosX=m_uUnitToTransport.GetLocationX();
								m_nGetUnitFirstPosY=m_uUnitToTransport.GetLocationY();
								m_nGetUnitFirstPosZ=m_uUnitToTransport.GetLocationZ();
								CalcMoveToPutGetPointCoords(m_nGetUnitFirstPosX, m_nGetUnitFirstPosY, m_nGetUnitFirstPosZ);
								CallMoveToPoint(m_nMoveToX, m_nMoveToY, m_nMoveToZ);
								uUnit=null;
								return MovingToGetUnit;
							}
						}
						while(uUnit!=null); //TODO: bug?
						EndEnumTargetsArray();
					}
				}
			}
		}
		return Nothing, 50;
	}

	state StartMoving{
		return Moving, 20;
	}

	state Moving{
		if(IsMoving()){
			return Moving;
		}
		NextCommand(true);
		return Nothing, 1;
	}

	state StartLanding{
		return Landing, 20;
	}

	state Landing{
		if(IsMoving()){
			if(
				(GetLocationX()==m_nMoveToX)
				&&
				(GetLocationY()==m_nMoveToY)
				&&
				(GetLocationZ()==m_nMoveToZ)
				&&
				!IsFreePoint(m_nMoveToX, m_nMoveToY, m_nMoveToZ)
			){
				if(!Land()){
					NextCommand(true);
					return Nothing;
				}
			}
			return Landing;
		}
		if(!Land()){
			NextCommand(true);
			return Nothing;
		}
		return Landing;
	}

	state Froozen{
		if(IsFroozen()){
			return Froozen;
		}
		return Nothing, 1;
	}

	state MovingToGetUnit{
		int nUnitPosX;
		int nUnitPosY;
		int nUnitPosZ;

		if(!m_uUnitToTransport.IsLive()){
			SetUnitToTransport(null);
			NextCommand(false);
			return Nothing, 1;
		}
		nUnitPosX=m_uUnitToTransport.GetLocationX();
		nUnitPosY=m_uUnitToTransport.GetLocationY();
		nUnitPosZ=m_uUnitToTransport.GetLocationZ();

		if(
			(nUnitPosZ!=m_nGetUnitFirstPosZ)
			||
			IsAlliance(m_uUnitToTransport)
			&&
			(Distance(nUnitPosX, nUnitPosY, m_nGetUnitFirstPosX, m_nGetUnitFirstPosY) >= 5)
		){
			//rezygnujemy
			SetUnitToTransport(null);
			NextCommand(false);
			return Nothing, 1;
		}
		if((nUnitPosX!=m_nGetUnitFirstPosX) || (nUnitPosY!=m_nGetUnitFirstPosY)){
			//zmienic cel jazdy
			CalcMoveToPutGetPointCoords(nUnitPosX, nUnitPosY, nUnitPosZ);
			CallMoveToPoint(m_nMoveToX, m_nMoveToY, m_nMoveToZ);
		}
		if(IsMoving()){
			return MovingToGetUnit;
		}
		if(
			(GetLocationX()==m_nMoveToX)
			&&
			(GetLocationY()==m_nMoveToY)
			&&
			(GetLocationZ()==m_nMoveToZ)
		){
			CallGetUnit(m_uUnitToTransport.GetLocationX(), m_uUnitToTransport.GetLocationY(), m_uUnitToTransport.GetLocationZ());
			return GettingUnit;
		}
		CalcMoveToPutGetPointCoords(nUnitPosX, nUnitPosY, nUnitPosZ);
		CallMoveToPoint(m_nMoveToX, m_nMoveToY, m_nMoveToZ);
		return MovingToGetUnit;
	}

	state GettingUnit{
		if(IsGettingUnit()){
			return GettingUnit;
		}
		SetUnitToTransport(null);
		m_nMoveToX=GetLocationX();
		m_nMoveToY=GetLocationY();
		m_nMoveToZ=GetLocationZ();
		CallMoveToPoint(GetLocationX(), GetLocationY(), GetLocationZ());
		NextCommand(true);
		return StartMoving;
	}

	state MovingToPutUnit{
		if(IsMoving()){
			return MovingToPutUnit;
		}
		if(
			(GetLocationX()==m_nMoveToX)
			&&
			(GetLocationY()==m_nMoveToY)
			&&
			(GetLocationZ()==m_nMoveToZ)
		){
			CallPutUnit(m_nPutPosX, m_nPutPosY, m_nPutPosZ);
			return PuttingUnit;
		}
		CallMoveToPoint(m_nMoveToX, m_nMoveToY, m_nMoveToZ);
		return MovingToPutUnit;
	}

	state PuttingUnit{
		if(IsPuttingUnit()){
			return PuttingUnit;
		}
		m_nMoveToX=GetLocationX();
		m_nMoveToY=GetLocationY();
		m_nMoveToZ=GetLocationZ();
		CallMoveToPoint(GetLocationX(), GetLocationY(), GetLocationZ());
		NextCommand(true);
		return StartMoving;
	}

	state MovingToDropUnit{
		if(IsMoving()){
			return MovingToDropUnit;
		}
		if(
			(GetLocationX()==m_nMoveToX)
			&&
			(GetLocationY()==m_nMoveToY)
			&&
			(GetLocationZ()==m_nMoveToZ)
		){
			CallDropUnit(m_nPutPosX, m_nPutPosY, m_nPutPosZ);
			return DroppingUnit;
		}
		CallMoveToPoint(m_nMoveToX, m_nMoveToY, m_nMoveToZ);
		return MovingToDropUnit;
	}

	state DroppingUnit{
		if(IsDroppingUnit()){
			return DroppingUnit;
		}
		m_nMoveToX=GetLocationX();
		m_nMoveToY=GetLocationY();
		m_nMoveToZ=GetLocationZ();
		CallMoveToPoint(GetLocationX(), GetLocationY(), GetLocationZ());
		NextCommand(true);
		return StartMoving;
	}

	event OnFreezeForSupplyOrRepair(int nFreezeTicks){
		CallFreeze(nFreezeTicks);
		return Froozen;
		true;
	}

	command Initialize(){
		//pozwolic dzialkom strzelac samym (o ile sa jakies)
		SetCannonFireMode(-1, 1);
		false;
	}

	command Uninitialize(){
		//wykasowac referencje
		SetUnitToTransport(null);
		false;
	}

	command Move(int nGx, int nGy, int nLz) hidden button "translateCommandMove" description "translateCommandMoveDescription" hotkey priority 21{
		SetUnitToTransport(null);
		m_nMoveToX=nGx;
		m_nMoveToY=nGy;
		m_nMoveToZ=nLz;
		CallMoveToPoint(m_nMoveToX, m_nMoveToY, m_nMoveToZ);
		state StartMoving;
		true;
	}

	command Enter(unit uEntrance) hidden button "translateCommandEnter"{
		SetUnitToTransport(null);
		m_nMoveToX=GetEntranceX(uEntrance);
		m_nMoveToY=GetEntranceY(uEntrance);
		m_nMoveToZ=GetEntranceZ(uEntrance);
		CallMoveInsideObject(uEntrance);
		state StartMoving;
		true;
	}

	command Stop() button "translateCommandStop" description "translateCommandStopDescription" hotkey priority 20{
		SetUnitToTransport(null);
		CallStopMoving();
		state StartMoving;
		true;
	}

	command SetLights(int nMode) button comboLights description "translateCommandStateLightsModeDescription" hotkey priority 204{
		if(nMode==-1){
			comboLights=(comboLights+1)%3;
		}else{
			comboLights=nMode;
		}
		SetLightsMode(comboLights);
		NextCommand(false);
	}

	command Land() button "translateCommandLand" description "translateCommandLandDescription" hotkey priority 31{
		SetUnitToTransport(null);
		m_nLandCounter=1;
		if(Land()){
			state StartLanding;
		}else{
			NextCommand(true);
		}
	}

	command TransporterGetUnit(unit uGetUnit) hidden button "translateCommandTransporterGetUnit" description "translateCommandTransporterGetUnitDescription" hotkey priority 101{
		if(!HaveUnitOnHook()){
			SetUnitToTransport(uGetUnit);
			m_nGetUnitFirstPosX=m_uUnitToTransport.GetLocationX();
			m_nGetUnitFirstPosY=m_uUnitToTransport.GetLocationY();
			m_nGetUnitFirstPosZ=m_uUnitToTransport.GetLocationZ();
			CalcMoveToPutGetPointCoords(m_nGetUnitFirstPosX, m_nGetUnitFirstPosY, m_nGetUnitFirstPosZ);
			CallMoveToPoint(m_nMoveToX, m_nMoveToY, m_nMoveToZ);
			state MovingToGetUnit;
		}else{
			NextCommand(false);
		}
	}

	command TransporterPutUnit() button "translateCommandTransporterPutUnit" description "translateCommandTransporterPutUnitDescription" hotkey priority 102{
		if(HaveUnitOnHook()){
			if(IsHelicopter()){
				if(FindFreePlaceToPutUnitFromHook(GetLocationX(), GetLocationY(), GetLocationZ(), 6)){
					m_nPutPosX=GetFoundFreePlaceToPutUnitX();
					m_nPutPosY=GetFoundFreePlaceToPutUnitY();
					m_nPutPosZ=GetFoundFreePlaceToPutUnitZ();
					CalcMoveToPutGetPointCoords(m_nPutPosX, m_nPutPosY, m_nPutPosZ);
					CallMoveToPoint(m_nMoveToX, m_nMoveToY, m_nMoveToZ);
					state MovingToPutUnit;
				}else{
					NextCommand(false);
				}
			}else{
				//najpierw sprawdzic czy jestesmy blisko miejsca z ktorego poprzednio wzielismy
				//unit i czy mozna go tam odstawic
				if(
					(Distance(GetLocationX(), GetLocationY(), m_nGetUnitFirstPosX, m_nGetUnitFirstPosY)==1)
					&&
					CanPutUnitFromHookInPoint(m_nGetUnitFirstPosX, m_nGetUnitFirstPosY, m_nGetUnitFirstPosZ)
				){
					m_nPutPosX=m_nGetUnitFirstPosX;
					m_nPutPosY=m_nGetUnitFirstPosY;
					m_nPutPosZ=m_nGetUnitFirstPosZ;
					CalcMoveToPutGetPointCoords(m_nPutPosX, m_nPutPosY, m_nPutPosZ);
					CallMoveToPoint(m_nMoveToX, m_nMoveToY, m_nMoveToZ);
					state MovingToPutUnit;
				}else{
					if(FindFreePlaceToPutUnitFromHook(GetLocationX(), GetLocationY(), GetLocationZ(), 6)){
						m_nPutPosX=GetFoundFreePlaceToPutUnitX();
						m_nPutPosY=GetFoundFreePlaceToPutUnitY();
						m_nPutPosZ=GetFoundFreePlaceToPutUnitZ();
						CalcMoveToPutGetPointCoords(m_nPutPosX, m_nPutPosY, m_nPutPosZ);
						CallMoveToPoint(m_nMoveToX, m_nMoveToY, m_nMoveToZ);
						state MovingToPutUnit;
					}else{
						NextCommand(false);
					}
				}
			}
		}else{
			NextCommand(false);
		}
	}

	command TransporterPutUnitToPoint(int nX, int nY, int nZ) button "translateCommandTransporterPutUnitToPoint" description "translateCommandTransporterPutUnitToPointDescription" hotkey priority 103{
		if(HaveUnitOnHook()){
			m_nPutPosX=nX;
			m_nPutPosY=nY;
			m_nPutPosZ=nZ;
			CalcMoveToPutGetPointCoords(m_nPutPosX, m_nPutPosY, m_nPutPosZ);
			CallMoveToPoint(m_nMoveToX, m_nMoveToY, m_nMoveToZ);
			state MovingToPutUnit;
		}else{
			NextCommand(false);
		}
	}

	command TransporterDropUnit() button "translateCommandTransporterDropUnit" description "translateCommandTransporterDropUnitDescription" hotkey priority 105{
		if(HaveUnitOnHook() && IsHelicopter()){
			m_nPutPosX=GetLocationX();
			m_nPutPosY=GetLocationY();
			m_nPutPosZ=GetLocationZ();
			CalcMoveToPutGetPointCoords(m_nPutPosX, m_nPutPosY, m_nPutPosZ);
			CallMoveToPoint(m_nMoveToX, m_nMoveToY, m_nMoveToZ);
			state MovingToDropUnit;
		}else{
			NextCommand(false);
		}
	}

	command TransporterDropUnitToPoint(int nX, int nY, int nZ) button "translateCommandTransporterDropUnitToPoint" description "translateCommandTransporterDropUnitToPointDescription" hotkey priority 106{
		if(HaveUnitOnHook() && IsHelicopter()){
			m_nPutPosX=nX;
			m_nPutPosY=nY;
			m_nPutPosZ=nZ;
			CalcMoveToPutGetPointCoords(m_nPutPosX, m_nPutPosY, m_nPutPosZ);
			CallMoveToPoint(m_nMoveToX, m_nMoveToY, m_nMoveToZ);
			state MovingToDropUnit;
		}else{
			NextCommand(false);
		}
	}

	command TransporterSetTransportMode(int nMode) button comboTransporterMode description "translateCommandTransporterSetModeDescription" hotkey priority 210{
		if(nMode==-1){
			comboTransporterMode=(comboTransporterMode+1)%2;
		}else{
			assert(nMode==0);
			comboTransporterMode=nMode;
		}
		if(comboTransporterMode==TRANSPORTER_MODE_AUTO){
			if(m_bValidAutoGetPoint){
				SetAutoGetPoint(m_nAutoGetPointX, m_nAutoGetPointY, m_nAutoGetPointZ);
			}
			if(m_bValidAutoPutPoint){
				SetAutoPutPoint(m_nAutoPutPointX, m_nAutoPutPointY, m_nAutoPutPointZ);
			}
		}else{ //manual
			//skasowanie aby punkty nie byly malowane
			InvalidateAutoGetPoint();
			InvalidateAutoPutPoint();
		}
		NextCommand(true);
	}

	command TransporterSetAutoGetPoint(int nX, int nY, int nZ) button "translateCommandTransporterSetAutoGetPoint" description "translateCommandTransporterSetAutoGetPointDescription" hotkey priority 211{
		m_nAutoGetPointX=nX;
		m_nAutoGetPointY=nY;
		m_nAutoGetPointZ=nZ;
		m_bValidAutoGetPoint=true;
		if(comboTransporterMode==TRANSPORTER_MODE_AUTO){
			SetAutoGetPoint(nX, nY, nZ);
		}
		NextCommand(true);
	}

	command TransporterSetAutoPutPoint(int nX, int nY, int nZ) button "translateCommandTransporterSetAutoPutPoint" description "translateCommandTransporterSetAutoPutPointDescription" hotkey priority 212{
		m_nAutoPutPointX=nX;
		m_nAutoPutPointY=nY;
		m_nAutoPutPointZ=nZ;
		m_bValidAutoPutPoint=true;
		if(comboTransporterMode==TRANSPORTER_MODE_AUTO){
			SetAutoPutPoint(nX, nY, nZ);
		}
		NextCommand(true);
	}

	command SpecialShowTransporterAutoGetPoint() button "translateCommandShowTransporterAutoGetPoint" description "translateCommandShowTransporterAutoGetPointDescription" hotkey priority 213{
		//special command, no implementation
	}

	command SpecialShowTransporterAutoPutPoint() button "translateCommandShowTransporterAutoPutPoint" description "translateCommandShowTransporterAutoPutPointDescription" hotkey priority 214{
		//special command, no implementation
	}

	command SpecialChangeUnitsScript() button "translateCommandChangeScript" description "translateCommandChangeScriptDescription" hotkey priority 254{
		//special command, no implementation
	}
}
