module("moonscript.transform", package.seeall)
local types = require("moonscript.types")
local util = require("moonscript.util")
local data = require("moonscript.data")
local ntype, build, smart_node = types.ntype, types.build, types.smart_node
local insert = table.insert
NameProxy = (function(_parent_0)
  local _base_0 = {
    get_name = function(self, scope)
      if not self.name then
        self.name = scope:free_name(self.prefix, true)
      end
      return self.name
    end,
    chain = function(self, ...)
      local items = {
        ...
      }
      items = (function()
        local _accum_0 = { }
        local _len_0 = 0
        do
          local _item_0 = items
          for _index_0 = 1, #_item_0 do
            local i = _item_0[_index_0]
            local _value_0
            if type(i) == "string" then
              _value_0 = {
                "dot",
                i
              }
            else
              _value_0 = i
            end
            if _value_0 ~= nil then
              _len_0 = _len_0 + 1
              _accum_0[_len_0] = _value_0
            end
          end
        end
        return _accum_0
      end)()
      return build.chain({
        base = self,
        unpack(items)
      })
    end,
    __tostring = function(self)
      if self.name then
        return ("name<%s>"):format(self.name)
      else
        return ("name<prefix(%s)>"):format(self.prefix)
      end
    end
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, getmetatable(_parent_0).__index)
  end
  local _class_0 = setmetatable({
    __init = function(self, prefix)
      self.prefix = prefix
      self[1] = "temp_name"
    end
  }, {
    __index = _base_0,
    __call = function(mt, ...)
      local self = setmetatable({}, _base_0)
      mt.__init(self, ...)
      return self
    end
  })
  _base_0.__class = _class_0
  return _class_0
end)()
local Run
Run = (function(_parent_0)
  local _base_0 = {
    call = function(self, state)
      return self.fn(state)
    end
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, getmetatable(_parent_0).__index)
  end
  local _class_0 = setmetatable({
    __init = function(self, fn)
      self.fn = fn
      self[1] = "run"
    end
  }, {
    __index = _base_0,
    __call = function(mt, ...)
      local self = setmetatable({}, _base_0)
      mt.__init(self, ...)
      return self
    end
  })
  _base_0.__class = _class_0
  return _class_0
end)()
local constructor_name = "new"
local transformer
transformer = function(transformers)
  return function(n)
    transformer = transformers[ntype(n)]
    if transformer then
      return transformer(n) or n
    else
      return n
    end
  end
end
stm = transformer({
  class = function(node)
    local _, name, parent_val, tbl = unpack(node)
    local constructor = nil
    local properties = (function()
      local _accum_0 = { }
      local _len_0 = 0
      do
        local _item_0 = tbl[2]
        for _index_0 = 1, #_item_0 do
          local entry = _item_0[_index_0]
          local _value_0
          if entry[1] == constructor_name then
            constructor = entry[2]
            _value_0 = nil
          else
            _value_0 = entry
          end
          if _value_0 ~= nil then
            _len_0 = _len_0 + 1
            _accum_0[_len_0] = _value_0
          end
        end
      end
      return _accum_0
    end)()
    tbl[2] = properties
    local parent_cls_name = NameProxy("parent")
    local base_name = NameProxy("base")
    local self_name = NameProxy("self")
    local cls_name = NameProxy("class")
    if not constructor then
      constructor = build.fndef({
        args = {
          {
            "..."
          }
        },
        arrow = "fat",
        body = {
          build["if"]({
            cond = parent_cls_name,
            ["then"] = {
              build.chain({
                base = "super",
                {
                  "call",
                  {
                    "..."
                  }
                }
              })
            }
          })
        }
      })
    else
      smart_node(constructor)
      constructor.arrow = "fat"
    end
    local cls = build.table({
      {
        "__init",
        constructor
      }
    })
    local cls_mt = build.table({
      {
        "__index",
        base_name
      },
      {
        "__call",
        build.fndef({
          args = {
            {
              "cls"
            },
            {
              "..."
            }
          },
          body = {
            build.assign_one(self_name, build.chain({
              base = "setmetatable",
              {
                "call",
                {
                  "{}",
                  base_name
                }
              }
            })),
            build.chain({
              base = "cls.__init",
              {
                "call",
                {
                  self_name,
                  "..."
                }
              }
            }),
            self_name
          }
        })
      }
    })
    cls = build.chain({
      base = "setmetatable",
      {
        "call",
        {
          cls,
          cls_mt
        }
      }
    })
    local value = nil
    do
      local _with_0 = build
      value = _with_0.block_exp({
        Run(function(self)
          return self:set("super", function(block, chain)
            local calling_name = block:get("current_block")
            local slice = (function()
              local _accum_0 = { }
              local _len_0 = 0
              do
                local _item_0 = chain
                for _index_0 = 3, #_item_0 do
                  local item = _item_0[_index_0]
                  _len_0 = _len_0 + 1
                  _accum_0[_len_0] = item
                end
              end
              return _accum_0
            end)()
            slice[1] = {
              "call",
              {
                "self",
                unpack(slice[1][2])
              }
            }
            local act
            if ntype(calling_name) ~= "value" then
              act = "index"
            else
              act = "dot"
            end
            return {
              "chain",
              parent_cls_name,
              {
                act,
                calling_name
              },
              unpack(slice)
            }
          end)
        end),
        _with_0.assign_one(parent_cls_name, parent_val == "" and "nil" or parent_val),
        _with_0.assign_one(base_name, tbl),
        _with_0.assign_one(base_name:chain("__index"), base_name),
        build["if"]({
          cond = parent_cls_name,
          ["then"] = {
            _with_0.chain({
              base = "setmetatable",
              {
                "call",
                {
                  base_name,
                  _with_0.chain({
                    base = "getmetatable",
                    {
                      "call",
                      {
                        parent_cls_name
                      }
                    },
                    {
                      "dot",
                      "__index"
                    }
                  })
                }
              }
            })
          }
        }),
        _with_0.assign_one(cls_name, cls),
        _with_0.assign_one(base_name:chain("__class"), cls_name),
        cls_name
      })
      value = _with_0.group({
        _with_0.declare({
          names = {
            name
          }
        }),
        _with_0.assign({
          names = {
            name
          },
          values = {
            value
          }
        })
      })
    end
    return value
  end
})
value = transformer({
  chain = function(node)
    local stub = node[#node]
    if type(stub) == "table" and stub[1] == "colon_stub" then
      table.remove(node, #node)
      local base_name = NameProxy("base")
      local fn_name = NameProxy("fn")
      return build.block_exp({
        build.assign({
          names = {
            base_name
          },
          values = {
            node
          }
        }),
        build.assign({
          names = {
            fn_name
          },
          values = {
            build.chain({
              base = base_name,
              {
                "dot",
                stub[2]
              }
            })
          }
        }),
        build.fndef({
          args = {
            {
              "..."
            }
          },
          body = {
            build.chain({
              base = fn_name,
              {
                "call",
                {
                  base_name,
                  "..."
                }
              }
            })
          }
        })
      })
    end
  end,
  block_exp = function(node)
    local _, body = unpack(node)
    local fn = build.fndef({
      body = body
    })
    return build.chain({
      base = {
        "parens",
        fn
      },
      {
        "call",
        { }
      }
    })
  end
})
