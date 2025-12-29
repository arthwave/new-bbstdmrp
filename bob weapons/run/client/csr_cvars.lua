ddCSLuaFile()

CSR = {}
if (!ConVarExists("cl_csr_extra_muzzle_flash")) then
	CSR.UseMuzzle = CreateConVar("cl_csr_extra_muzzle_flash", "0", {FCVAR_CLIENT, FCVAR_ARCHIVE})
end
if (!ConVarExists("cl_csr_extra_bullet_ejection")) then
	CSR.ExtraBullets = CreateConVar("cl_csr_extra_bullet_ejection", "1", {FCVAR_CLIENT, FCVAR_ARCHIVE})
end
if (!ConVarExists("cl_csr_hit_effects")) then
	CSR.HitEffects = CreateConVar("cl_csr_hit_effects", "0", {FCVAR_CLIENT, FCVAR_ARCHIVE})
endC