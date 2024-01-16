
SWEP.Base = "weapon_base"
SWEP.PrintName = "Money Giver"
SWEP.Category = "Other"
SWEP.Spawnable = true

SWEP.Author			= "Fesiug"
SWEP.Contact		= ""
SWEP.Purpose		= "Give money, drop money, write checks."
SWEP.Instructions	= "PRIMARY ATTACK to give money.\nSECONDARY ATTACK to drop money or a check.\nRELOAD to change offer."

SWEP.Slot = 1

SWEP.ViewModel = "models/weapons/fesi_moneygiver4.mdl"
SWEP.ViewModelFOV = 75
SWEP.UseHands = true
SWEP.WorldModel = "models/weapons/fesi_moneygiver_wmodel1.mdl"

SWEP.m_WeaponDeploySpeed = 10

SWEP.Primary.Ammo = "none"
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = true

SWEP.Secondary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = true

function SWEP:SetupDataTables()
	self:NetworkVar( "Float", 0, "Delay" )
end

function SWEP:GetVM()
	return self:GetOwner():GetViewModel()
end

function SWEP:EZAnim( seqname, rate )
	print(self:GetVM():GetModel())
	self:GetVM():SendViewModelMatchingSequence( self:GetVM():LookupSequence( seqname ) )
	self:GetVM():SetPlaybackRate( rate or 1 )
end

function SWEP:PrimaryAttack()
	if self:GetDelay() <= CurTime() then
		self:EZAnim( "fire" )
		self:SetDelay( CurTime() + 1.5 )
		if CLIENT and IsFirstTimePredicted() then
			RunConsoleCommand( "darkrp", "give", (self.Amount) )
		end
	end
	return true
end

function SWEP:SecondaryAttack()
	if self:GetDelay() <= CurTime() then
		self:EZAnim( "fire" )
		self:SetDelay( CurTime() + 1.5 )
		if CLIENT and IsFirstTimePredicted() then
			if self.CheckFor:IsValid() then
				local recip = "" .. self.CheckFor:Nick() .. ""
				print(self.CheckFor, self.CheckFor:Nick(), recip, self.Amount)
				RunConsoleCommand( "darkrp", "check", recip, self.Amount )
			else
				RunConsoleCommand( "darkrp", "dropmoney", self.Amount )
			end
		end
	end
	return true
end

function SWEP:Reload()
	if CLIENT and IsFirstTimePredicted() then
		if IsValid(MGUI) then MGUI:Remove() end
		MGUI = vgui.Create("DFrame")
		local s = ScreenScaleH
		MGUI:SetSize( s(120), s(88) )
		MGUI:SetTitle("Offer...")
		MGUI:SetIcon("icon16/money.png")
		MGUI:Center()
		MGUI:MakePopup()

		local label = MGUI:Add("DLabel")
		label:SetText("Amount to offer")
		label:SetTall( s(14) )
		label:Dock( TOP )
		label:DockMargin( 0, s(-4), 0, s(0) )

		local money = MGUI:Add("DNumberWang")
		money:SetTall( s(14) )
		money:Dock( TOP )
		money:DockMargin( 0, 0, 0, s(4) )
		money:SetInterval( 100 )
		money:SetMax( 2^31 )

		if self.Amount then
			money:SetValue( self.Amount )
		end

		function money.OnValueChanged( sell, value )
			self.Amount = value
		end

		function money.OnEnter()
			MGUI:Remove()
		end

		local label = MGUI:Add("DLabel")
		label:SetText("Who to offer to (optional)")
		label:SetTall( s(14) )
		label:Dock( TOP )
		label:DockMargin( 0, s(-4), 0, s(0) )

		local combo = MGUI:Add("DComboBox")
		combo:SetTall( s(14) )
		combo:Dock( TOP )
		combo:DockMargin( 0, 0, 0, s(4) )
		combo:AddChoice( "*none*", NULL )
		for _, ply in player.Iterator() do
			combo:AddChoice( ply:Nick(), ply )
		end

		function combo.OnSelect( sell, num, value, data )
			self.CheckFor = data
		end

		local close = MGUI:Add("DButton")
		close:SetText("Close")
		close:SetTall( s(14) )
		close:Dock( TOP )
		close:DockMargin( 0, 0, 0, s(4) )

		function close:DoClick()
			MGUI:Remove()
		end
	end
	return true
end

function SWEP:Deploy()
	if SERVER then self:CallOnClient("Deploy") end
	if CLIENT then
		self.Amount = 0
		self.CheckFor = NULL
	end
	self:EZAnim( "draw", 1 )
	self:SetHoldType("slam")
	return true
end

function SWEP:Holster()
	if SERVER then self:CallOnClient("Holster") end
	if CLIENT then
		self.Amount = 0
		self.CheckFor = NULL
	end
	return true
end

if CLIENT then
	local s = ScreenScaleH
	surface.CreateFont("MG_1", {
		font = "Trebuchet MS",
		size = s(24),
	})
	surface.CreateFont("MG_2", {
		font = "Trebuchet MS",
		size = s(12),
	})
	
	function SWEP:DrawHUD()
		local w, h = ScrW()/2, ScrH()*0.65
		local ctext = "OFFERING"
		if IsValid( self.CheckFor ) then
			ctext = "OFFERING FOR " .. self.CheckFor:Nick()
		end
		draw.SimpleTextOutlined( ctext, "MG_2", w, h, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, s(1), color_black )
		draw.SimpleTextOutlined( "$" .. tostring(self.Amount):Comma(), "MG_1", w, h + s(10), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, s(1), color_black )
		draw.SimpleTextOutlined( "Press [ " .. input.LookupBinding( "+attack" ):upper() .. " ] to give", "MG_2", w, h + s(10+22), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, s(1), color_black )
		draw.SimpleTextOutlined( "Press [ " .. input.LookupBinding( "+attack2" ):upper() .. " ] to drop money or check", "MG_2", w, h + s(10+22+10), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, s(1), color_black )
		draw.SimpleTextOutlined( "Press [ " .. input.LookupBinding( "+reload" ):upper() .. " ] to change offer", "MG_2", w, h + s(10+22+10+10), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, s(1), color_black )
	end
end