unction EFFECT:Init( data )
	if (CLIENT and !CSR.HitEffects:GetBool()) then return end	

	local vOffset = data:GetOrigin()

	local emitter = ParticleEmitter( vOffset )


	local particle = emitter:Add( "particle/particle_smokegrenade", vOffset )

	particle:SetVelocity( 200 * 1 * data:GetNormal() + 8 * VectorRand() )
	particle:SetAirResistance(400)

	particle:SetDieTime( math.Rand( 0.5, 1.5 ) )

	particle:SetStartAlpha( math.Rand( 50, 150 ) )
	particle:SetEndAlpha( math.Rand( 0, 5 ) )

	particle:SetStartSize( math.Rand( 4, 6 ) )
	particle:SetEndSize( math.Rand( 26, 38 ) )

	particle:SetRoll( math.Rand( -25, 25 ) )
	particle:SetRollDelta( math.Rand( -0.05, 0.05 ) )

	particle:SetColor( 120, 120, 120 )

	local particle = emitter:Add( "effects/muzzleflash"..math.random(1,4), vOffset )

	particle:SetVelocity( 100 * data:GetNormal() )
	particle:SetAirResistance( 200 )

	particle:SetDieTime( 0.09 )

	particle:SetStartAlpha( 160 )
	particle:SetEndAlpha( 0 )

	particle:SetStartSize( 4 )
	particle:SetEndSize( 1 )

	particle:SetRoll( math.Rand(180,480) )
	particle:SetRollDelta( math.Rand(-1,1) )

	particle:SetColor(255,255,255)	

	local particle = emitter:Add( "sprites/heatwave", vOffset )

	particle:SetVelocity( 80 * data:GetNormal() + 20 * VectorRand() )
	particle:SetAirResistance( 200 )

	particle:SetDieTime( math.Rand(0.1, 0.15) )

	particle:SetStartSize( math.random(7.5,15) )
	particle:SetEndSize( 2 )


	particle:SetRoll( math.Rand(180,480) )
	particle:SetRollDelta( math.Rand(-1,1) )

	emitter:Finish()
end

function EFFECT:Think( )

	return false
end

function EFFECT:Render()

endf