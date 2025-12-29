unction EFFECT:Init(data)
	if (CLIENT and !CSR.UseMuzzle:GetBool()) then return end
	
	self.WeaponEnt = data:GetEntity()
	if !self.WeaponEnt or !IsValid(self.WeaponEnt) then return end
	self.Attachment = data:GetAttachment()
	
	self.Position = self:GetTracerShootPos(data:GetOrigin(), self.WeaponEnt, self.Attachment)
	self.Forward = data:GetNormal()
	self.Angle = self.Forward:Angle()
	self.Right = self.Angle:Right()
	
	local WeaponOwner = self.WeaponEnt:GetOwner()
	if !WeaponOwner or !IsValid(WeaponOwner) then return end
	local AddVel = WeaponOwner:GetVelocity()

	local emitter = ParticleEmitter(self.Position)
		
	local particle = emitter:Add( "sprites/heatwave", self.Position - self.Forward * 4 )

	particle:SetVelocity( 80 * self.Forward + 20 * VectorRand() + 1.05 * AddVel )
	particle:SetGravity( Vector( 0, 0, 100 ) )
	particle:SetAirResistance( 160 )

	particle:SetDieTime( math.Rand( 0.2, 0.25 ) )

	particle:SetStartSize( math.random( 25, 40 ) )
	particle:SetEndSize( 10 )

	particle:SetRoll( math.Rand( 180, 480 ) )
	particle:SetRollDelta( math.Rand( -1, 1 ) )

	local particle = emitter:Add( "particle/particle_smokegrenade", self.Position )

	particle:SetVelocity( 180 * self.Forward + 8 * VectorRand() + AddVel )
	particle:SetAirResistance( 400 )
	particle:SetGravity( Vector(0, 0, math.Rand(100, 200) ) )

	particle:SetDieTime( math.Rand( 0.5, 1.0 ) )

	particle:SetStartAlpha( math.Rand( 25, 70 ) )
	particle:SetEndAlpha( 0 )

	particle:SetStartSize( math.Rand( 3, 7 ) )
	particle:SetEndSize( math.Rand( 20, 50 ) )

	particle:SetRoll( math.Rand( -25, 25 ) )
	particle:SetRollDelta( math.Rand( -0.05, 0.05 ) )

	particle:SetColor( 120, 120, 120 )

	if math.random( 1, 2 ) == 1 then
		for i = -1, 1 do 
			local particle = emitter:Add( "effects/muzzleflash"..math.random( 1, 4 ), self.Position - 3 * self.Forward + 2 * i * self.Right)

			particle:SetVelocity( 75 * i * self.Right + AddVel )
			particle:SetGravity( AddVel )

			particle:SetDieTime( 0.1 )

			particle:SetStartAlpha( 150 )

			particle:SetStartSize( 1 )
			particle:SetEndSize( 6 )

			particle:SetRoll( math.Rand( 180, 480 ) )
			particle:SetRollDelta( math.Rand( -1, 1 ) )

			particle:SetColor( 255, 255, 255 )	
		end
	end

	local particle = emitter:Add( "effects/muzzleflash"..math.random( 1, 4 ), self.Position + 8 * self.Forward )

	particle:SetVelocity( 350 * self.Forward + 1.1 * AddVel )
	particle:SetAirResistance( 160 )

	particle:SetDieTime( 0.1 )

	particle:SetStartAlpha( 160 )
	particle:SetEndAlpha( 0 )

	particle:SetStartSize( 8 )
	particle:SetEndSize( 5 )

	particle:SetRoll( math.Rand( 180, 480 ) )
	particle:SetRollDelta( math.Rand( -1, 1) )

	particle:SetColor( 255, 255, 255 )	


	emitter:Finish()
end


function EFFECT:Think()

	return false
end


function EFFECT:Render()
endf