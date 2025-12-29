function ENT:Initialize()
    self:SetModel("models/props_interiors/VendingMachineSoda01a.mdl")
    self:SetMaterial("phoenix_storms/mat/mat_phx_carbonfiber2")
    
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetPhysics(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    -- Default state
    self:SetOwner(0)  -- NEUTRAL
    self:SetProgress(0)
end

function ENT:Think()
    -- This entity is updated by the server-side capture points core
    -- Just ensure it stays spawned
    return true
end

function ENT:Use(activator, caller)
    -- Could add UI interaction here in future
end
