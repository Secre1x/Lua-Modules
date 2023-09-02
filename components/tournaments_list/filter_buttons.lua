local Array = require('Module:Array')
local Class = require('Module:Class')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')
local Table = require('Module:Table')

local FilterButtons = {}

---@class Category
---@field name string
---@field query string?
---@field items string[]?
---@field defaultItems string[]?
---@field transform function?
---@field expandKey string?
---@field expandable boolean?
---@field order function?

---@return Html
function FilterButtons.getFromConfig()
	return FilterButtons.get(require('Module:FilterButtons/Config').categories)
end

---Entrypoint building a set of FilterButtons
---@param categories Category[]
---@return Html
function FilterButtons.get(categories)
	Array.forEach(categories, FilterButtons._loadCategories)

	local div = mw.html.create('div')

	for index, category in ipairs(categories) do
		Variables.varDefine('filterbuttons_defaults_' .. category.name, table.concat(category.defaultItems, ','))
		local buttons = FilterButtons._getButtonRow(category)
		if index > 1 then
			buttons:css('margin-top', '-7px')
		end
		div:node(buttons)
	end

	return div
end

---@param category Category
function FilterButtons._loadCategories(category)
	if category.items then
		if not category.defaultItems then
			category.defaultItems = category.items
		end
	end

	category.items = {}
	local tournaments = mw.ext.LiquipediaDB.lpdb(
		'tournament',
		{
			limit = 15,
			query = category.query,
			order = category.query .. ' ASC',
			groupby = category.query .. ' ASC'
		}
	)

	assert(type(tournaments) == 'table', tournaments)
	for _, tournament in ipairs(tournaments) do
		if not String.isEmpty(tournament[category.query]) then
			table.insert(category.items, tournament[category.query])
		end
	end

	if category.order then
		Array.orderInPlaceBy(category.items, category.order)
	end

	if not category.defaultItems then
		category.defaultItems = category.items
	end
end

---@param category Category
function FilterButtons._getButtonRow(category)
	local buttons = mw.html.create('div')
		:addClass('filter-buttons')
		:attr('data-filter', 'data-filter')
		:attr('data-filter-effect','fade')
		:attr('data-filter-group', 'filterbuttons-' .. category.name)
		:css('margin','2px')
		:css('margin-bottom','7px')
		:css('display','flex')
		:css('justify-content','center')
		:css('align-items','center')
		:css('flex-flow','row wrap')
		:tag('span')
			:addClass('filter-button')
			:addClass('filter-button-all')
			:css('margin-top','5px')
			:css('font-size','9pt')
			:css('padding', '2px')
			:attr('data-filter-on', 'all')
			:wikitext('All')
			:done()

	for _, value in ipairs(category.items or {}) do
		local text = category.transform and category.transform(value) or value
		local button = mw.html.create('span')
			:addClass('filter-button')
			:css('margin-top','5px')
			:css('font-size','10pt')
			:css('flex-grow','1')
			:css('max-width','33%')
			:css('text-overflow','ellipsis')
			:css('overflow','hidden')
			:css('text-align','center')
			:css('padding', '2px')
			:attr('data-filter-on', value)
			:wikitext(text)
		if Table.includes(category.defaultItems, value) then
			button:addClass('filter-button--active')
		end
		buttons:node(button)
	end

	if String.isNotEmpty(category.expandKey) then
		local dropdownButton = mw.html.create('div')
			:addClass('filter-buttons')
			:attr('data-filter', 'data-filter')
			:attr('data-filter-effect','fade')
			:attr('data-filter-group', 'tournaments-list-dropdown')
			:css('display','flex')
			:css('padding','1px')
			:css('justify-content','center')
			:css('align-items','center')
			:css('flex-flow','row wrap')
			:node(mw.html.create('span')
				:addClass('filter-button')
				:css('margin-top','5px')
				:css('font-size','8pt')
				:css('padding-left','2px')
				:css('padding-right','2px')
				:attr('data-filter-on', 'all')
				:wikitext('&#8203;▼&#8203;'))
			:node(mw.html.create('span')
				:addClass('filter-button')
				:css('display','none')
				:attr('data-filter-on', 'dropdown-' .. category.expandKey)
				:wikitext('Dummy'))
		buttons:node(dropdownButton)
	end

	if category.expandable then
		local section = mw.html.create('div')
			:addClass('filter-category--hidden')
			:attr('data-filter-group', 'tournaments-list-dropdown')
        	:attr('data-filter-category', 'dropdown-' .. category.name)
			:css('margin-top','-8px')
			:node(buttons)
		return section
	end

	return buttons
end

return Class.export(FilterButtons)
