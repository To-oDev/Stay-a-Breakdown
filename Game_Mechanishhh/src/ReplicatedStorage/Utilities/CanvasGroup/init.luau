local CanvasGroup = {}
CanvasGroup.__index = CanvasGroup

local TweenService = game:GetService("TweenService")
local transparencyTypes = require(script:FindFirstChild("transparencyTypes"))

-- =========================
--  CONSTRUCTOR
-- =========================

function CanvasGroup.new(root: Instance?, affectObject: boolean?)
	local self = setmetatable({}, CanvasGroup)

	self.object = root
	self.affectObject = (affectObject == nil) and true or affectObject

	self.connections = {}
	self.childrenCache = {}      -- Solo GuiObjects (para SetProperty)
	self.propertiesCache = {}    -- [inst] = { [propName] = originalValue }

	self._currentTransparency = 0
	self._tweenValue = nil
	self._currentTween = nil

	-- conexiones específicas para descendientes (por si quieres diferenciarlas)
	self._descendantAddedConn = nil
	self._descendantRemovingConn = nil

	return self
end

-- =========================
--  UTILIDADES INTERNAS
-- =========================

-- Fórmula:
-- t = 0 -> valor original
-- t = 1 -> 1 (invisible)
local function applyTransparency(original: number, t: number): number
	return original + (1 - original) * t
end

-- Cachea propiedades de una instancia (se llama desde _buildCache y desde _onDescendantAdded)
local function cacheInstance(self, inst: Instance)
	local propsList = transparencyTypes(inst)
	if not propsList then
		return
	end

	-- Cache de propiedades originales
	local instCache = self.propertiesCache[inst]
	if not instCache then
		instCache = {}
		self.propertiesCache[inst] = instCache
	end

	for _, propName in ipairs(propsList) do
		-- Solo guardamos el valor original una vez
		if instCache[propName] == nil then
			instCache[propName] = inst[propName]
		end
	end

	-- Para SetProperty, solo nos interesan GuiObjects
	if inst:IsA("GuiObject") then
		table.insert(self.childrenCache, inst)
	end
end

-- Reconstruye TODO el cache en una sola pasada (root + descendientes)
function CanvasGroup:_buildCache()
	table.clear(self.childrenCache)
	table.clear(self.propertiesCache)

	if not self.object then
		return
	end

	-- Incluir el objeto raíz si toca
	if self.affectObject then
		cacheInstance(self, self.object)
	end

	-- Un único recorrido de todos los descendientes
	for _, inst in ipairs(self.object:GetDescendants()) do
		cacheInstance(self, inst)
	end
end

-- Maneja nuevos hijos que se agregan después de PreloadComponents
function CanvasGroup:_onDescendantAdded(inst: Instance)
	-- cacheamos la instancia
	cacheInstance(self, inst)

	-- si la instancia tiene props cacheadas, aplicamos la transparencia actual
	local instCache = self.propertiesCache[inst]
	if instCache then
		for propName, originalValue in pairs(instCache) do
			inst[propName] = applyTransparency(originalValue, self._currentTransparency)
		end
	end
end

-- Limpia cache cuando se remueve un descendiente
function CanvasGroup:_onDescendantRemoving(inst: Instance)
	-- quitar de propertiesCache
	self.propertiesCache[inst] = nil

	-- quitar de childrenCache (lista lineal, es pequeña normalmente)
	for i = #self.childrenCache, 1, -1 do
		if self.childrenCache[i] == inst then
			table.remove(self.childrenCache, i)
		end
	end
end

-- Asegura que el NumberValue existe y está conectado
function CanvasGroup:_ensureTweenValue()
	if self._tweenValue then
		return
	end

	local value = Instance.new("NumberValue")
	value.Name = "CanvasGroupTransparency"
	value.Value = self._currentTransparency or 0
	self._tweenValue = value

	-- Un solo evento que aplica la transparencia a TODOS al mismo tiempo
	table.insert(self.connections, value.Changed:Connect(function(newVal)
		self:SetTransparency(newVal)
	end))
end

-- Asegura que tenemos listeners para hijos nuevos / removidos
function CanvasGroup:_ensureDescendantListeners()
	if not self.object then
		return
	end
	if self._descendantAddedConn then
		return
	end

	local addedConn = self.object.DescendantAdded:Connect(function(inst)
		self:_onDescendantAdded(inst)
	end)

	local removingConn = self.object.DescendantRemoving:Connect(function(inst)
		self:_onDescendantRemoving(inst)
	end)

	self._descendantAddedConn = addedConn
	self._descendantRemovingConn = removingConn

	table.insert(self.connections, addedConn)
	table.insert(self.connections, removingConn)
end

-- =========================
--  API PÚBLICA
-- =========================

function CanvasGroup:PreloadComponents()
	if not self.object then
		return
	end

	-- 1) Recolectar TODO de golpe
	self:_buildCache()

	-- 2) Asegurar NumberValue
	self:_ensureTweenValue()

	-- 3) Escuchar nuevos hijos / removidos
	self:_ensureDescendantListeners()

	-- 4) Aplicar el estado actual a todos (por si ya tenías alpha ≠ 0)
	self:SetTransparency(self._currentTransparency)
end

function CanvasGroup:SetTransparency(transparency: number)
	transparency = math.clamp(transparency, 0, 1)
	self._currentTransparency = transparency

	-- Un solo loop que toca TODAS las instancias cacheadas
	for inst, props in pairs(self.propertiesCache) do
		if inst and inst.Parent ~= nil then
			for propName, originalValue in pairs(props) do
				inst[propName] = applyTransparency(originalValue, transparency)
			end
		end
	end
end

function CanvasGroup:TweenTransparency(transparency: number, tweenInfo: TweenInfo?)
	transparency = math.clamp(transparency, 0, 1)
	tweenInfo = tweenInfo or TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	-- Nos aseguramos de que todo esté cacheado y conectado
	if not self._tweenValue or next(self.propertiesCache) == nil then
		self:PreloadComponents()
	end

	-- Cancelar tween anterior, si existe
	if self._currentTween then
		self._currentTween:Cancel()
		self._currentTween = nil
	end

	local tween = TweenService:Create(self._tweenValue, tweenInfo, { Value = transparency })
	self._currentTween = tween

	tween.Completed:Connect(function()
		if self._currentTween == tween then
			self._currentTween = nil
		end
	end)
	
	return tween
end

function CanvasGroup:SetProperty(property: string, value: any, onlyParent: boolean)
	-- Solo soportamos booleanos (Active, Visible, AutoButtonColor, etc.)
	if typeof(value) ~= "boolean" then
		return
	end
	
	if onlyParent then
		if self.object and self.object:IsA("GuiObject") then
			self.object[property] = value
		end
		
		return
	end
	
	for _, child in ipairs(self.childrenCache) do
		if child and child.Parent then
			child[property] = value
		end
	end
end

function CanvasGroup:Destroy()
	for _, conn in ipairs(self.connections) do
		if conn.Connected then
			conn:Disconnect()
		end
	end

	self.connections = {}

	if self._tweenValue then
		self._tweenValue:Destroy()
		self._tweenValue = nil
	end

	self.childrenCache = {}
	self.propertiesCache = {}

	self._descendantAddedConn = nil
	self._descendantRemovingConn = nil
end

return CanvasGroup