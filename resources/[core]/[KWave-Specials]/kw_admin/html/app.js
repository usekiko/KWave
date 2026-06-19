// DTF Admin - Enhanced NUI with searchable items and animations

const adminMenu = document.getElementById('admin-menu');
const modal = document.getElementById('modal');
const toastContainer = document.getElementById('toast-container');

let currentPlayers = [];
let currentAction = null;
let selectedItem = null;
let menuOpen = false;

// Complete item/weapon database
const itemDatabase = {
    // Weapons
    'weapon_pistol': { label: 'Pistol', category: 'weapons', icon: '🔫' },
    'weapon_combatpistol': { label: 'Combat Pistol', category: 'weapons', icon: '🔫' },
    'weapon_appistol': { label: 'AP Pistol', category: 'weapons', icon: '🔫' },
    'weapon_pistol50': { label: 'Pistol .50', category: 'weapons', icon: '🔫' },
    'weapon_microsmg': { label: 'Micro SMG', category: 'weapons', icon: '🔫' },
    'weapon_smg': { label: 'SMG', category: 'weapons', icon: '🔫' },
    'weapon_assaultsmg': { label: 'Assault SMG', category: 'weapons', icon: '🔫' },
    'weapon_assaultrifle': { label: 'Assault Rifle', category: 'weapons', icon: '🔫' },
    'weapon_carbinerifle': { label: 'Carbine Rifle', category: 'weapons', icon: '🔫' },
    'weapon_advancedrifle': { label: 'Advanced Rifle', category: 'weapons', icon: '🔫' },
    'weapon_mg': { label: 'MG', category: 'weapons', icon: '🔫' },
    'weapon_combatmg': { label: 'Combat MG', category: 'weapons', icon: '🔫' },
    'weapon_pumpshotgun': { label: 'Pump Shotgun', category: 'weapons', icon: '🔫' },
    'weapon_sawnoffshotgun': { label: 'Sawn-off Shotgun', category: 'weapons', icon: '🔫' },
    'weapon_assaultshotgun': { label: 'Assault Shotgun', category: 'weapons', icon: '🔫' },
    'weapon_sniperrifle': { label: 'Sniper Rifle', category: 'weapons', icon: '🔫' },
    'weapon_heavysniper': { label: 'Heavy Sniper', category: 'weapons', icon: '🔫' },
    'weapon_grenadelauncher': { label: 'Grenade Launcher', category: 'weapons', icon: '🔫' },
    'weapon_rpg': { label: 'RPG', category: 'weapons', icon: '🔫' },
    'weapon_minigun': { label: 'Minigun', category: 'weapons', icon: '🔫' },
    'weapon_grenade': { label: 'Grenade', category: 'weapons', icon: '💣' },
    'weapon_stickybomb': { label: 'Sticky Bomb', category: 'weapons', icon: '💣' },
    'weapon_molotov': { label: 'Molotov', category: 'weapons', icon: '🔥' },
    'weapon_knife': { label: 'Knife', category: 'weapons', icon: '🔪' },
    'weapon_bat': { label: 'Baseball Bat', category: 'weapons', icon: '🏏' },
    'weapon_crowbar': { label: 'Crowbar', category: 'weapons', icon: '🔧' },
    'weapon_golfclub': { label: 'Golf Club', category: 'weapons', icon: '🏌️' },
    'weapon_hammer': { label: 'Hammer', category: 'weapons', icon: '🔨' },
    'weapon_nightstick': { label: 'Nightstick', category: 'weapons', icon: '🚨' },
    'weapon_fireextinguisher': { label: 'Fire Extinguisher', category: 'weapons', icon: '🧯' },
    
    // Ammo
    'ammo-9': { label: '9mm Ammo', category: 'ammo', icon: '🔋' },
    'ammo-45': { label: '.45 Ammo', category: 'ammo', icon: '🔋' },
    'ammo-50': { label: '.50 Ammo', category: 'ammo', icon: '🔋' },
    'ammo-12g': { label: '12 Gauge Ammo', category: 'ammo', icon: '🔋' },
    'ammo-556': { label: '5.56mm Ammo', category: 'ammo', icon: '🔋' },
    'ammo-762': { label: '7.62mm Ammo', category: 'ammo', icon: '🔋' },
    'ammo-shotgun': { label: 'Shotgun Ammo', category: 'ammo', icon: '🔋' },
    'ammo-sniper': { label: 'Sniper Ammo', category: 'ammo', icon: '🔋' },
    'ammo-rocket': { label: 'RPG Ammo', category: 'ammo', icon: '🔋' },
    
    // Food
    'bread': { label: 'Bread', category: 'food', icon: '🍞' },
    'burger': { label: 'Burger', category: 'food', icon: '🍔' },
    'hotdog': { label: 'Hotdog', category: 'food', icon: '🌭' },
    'pizza': { label: 'Pizza Slice', category: 'food', icon: '🍕' },
    'sandwich': { label: 'Sandwich', category: 'food', icon: '🥪' },
    'taco': { label: 'Taco', category: 'food', icon: '🌮' },
    'donut': { label: 'Donut', category: 'food', icon: '🍩' },
    'chocolate': { label: 'Chocolate Bar', category: 'food', icon: '🍫' },
    'candy': { label: 'Candy', category: 'food', icon: '🍬' },
    'chips': { label: 'Chips', category: 'food', icon: '🥔' },
    'cooked_meat': { label: 'Cooked Meat', category: 'food', icon: '🥩' },
    'apple': { label: 'Apple', category: 'food', icon: '🍎' },
    'banana': { label: 'Banana', category: 'food', icon: '🍌' },
    'orange': { label: 'Orange', category: 'food', icon: '🍊' },
    
    // Drink
    'water': { label: 'Water', category: 'drink', icon: '💧' },
    'cola': { label: 'Cola', category: 'drink', icon: '🥤' },
    'coffee': { label: 'Coffee', category: 'drink', icon: '☕' },
    'energy_drink': { label: 'Energy Drink', category: 'drink', icon: '⚡' },
    'beer': { label: 'Beer', category: 'drink', icon: '🍺' },
    'wine': { label: 'Wine', category: 'drink', icon: '🍷' },
    'whiskey': { label: 'Whiskey', category: 'drink', icon: '🥃' },
    'vodka': { label: 'Vodka', category: 'drink', icon: '🍸' },
    'milk': { label: 'Milk', category: 'drink', icon: '🥛' },
    'juice': { label: 'Juice', category: 'drink', icon: '🧃' },
    'redbull': { label: 'Red Bull', category: 'drink', icon: '🥫' },
    
    // Medical
    'bandage': { label: 'Bandage', category: 'medical', icon: '🩹' },
    'medikit': { label: 'Medikit', category: 'medical', icon: '💊' },
    'firstaid': { label: 'First Aid Kit', category: 'medical', icon: '🏥' },
    'painkillers': { label: 'Painkillers', category: 'medical', icon: '💉' },
    'antibiotic': { label: 'Antibiotics', category: 'medical', icon: '🧬' },
    
    // Tools
    'phone': { label: 'Phone', category: 'tools', icon: '📱' },
    'radio': { label: 'Radio', category: 'tools', icon: '📻' },
    'gps': { label: 'GPS', category: 'tools', icon: '📡' },
    'lockpick': { label: 'Lockpick', category: 'tools', icon: '🔓' },
    'repairkit': { label: 'Repair Kit', category: 'tools', icon: '🔧' },
    'tirekit': { label: 'Tire Kit', category: 'tools', icon: '🔩' },
    'cleaningkit': { label: 'Cleaning Kit', category: 'tools', icon: '🧽' },
    'bodycam': { label: 'Bodycam', category: 'tools', icon: '📹' },
    'handcuffs': { label: 'Handcuffs', category: 'tools', icon: '⛓️' },
    'ziptie': { label: 'Zip Tie', category: 'tools', icon: '🔗' },
    'rope': { label: 'Rope', category: 'tools', icon: '🪢' },
    'screwdriver': { label: 'Screwdriver', category: 'tools', icon: '🪛' },
    'drill': { label: 'Drill', category: 'tools', icon: '🔩' },
    'flashlight': { label: 'Flashlight', category: 'tools', icon: '🔦' },
    
    // Money (virtual items)
    'money': { label: 'Cash Money', category: 'money', icon: '💵' },
    'black_money': { label: 'Dirty Money', category: 'money', icon: '💰' },
    'marked_money': { label: 'Marked Money', category: 'money', icon: '💸' },
    
    // Misc items
    'idcard': { label: 'ID Card', category: 'tools', icon: '🪪' },
    'wallet': { label: 'Wallet', category: 'tools', icon: '👛' },
    'bag': { label: 'Bag', category: 'tools', icon: '🎒' },
    'cigarette': { label: 'Cigarette', category: 'tools', icon: '🚬' },
    'lighter': { label: 'Lighter', category: 'tools', icon: '🔥' },
    'binoculars': { label: 'Binoculars', category: 'tools', icon: '🔭' },
    'parachute': { label: 'Parachute', category: 'tools', icon: '🪂' },
    'scuba': { label: 'Scuba Gear', category: 'tools', icon: '🤿' },
    'nightvision': { label: 'Night Vision', category: 'tools', icon: '🥽' },
    'kevlar': { label: 'Kevlar Vest', category: 'tools', icon: '🦺' },
    'armor': { label: 'Armor Plate', category: 'tools', icon: '🛡️' },
};

// Vehicle database
const vehicleDatabase = {
    'adder': { label: 'Adder', category: 'super' },
    'zentorno': { label: 'Zentorno', category: 'super' },
    't20': { label: 'T20', category: 'super' },
    'osiris': { label: 'Osiris', category: 'super' },
    'turismor': { label: 'Turismo R', category: 'super' },
    'entityxf': { label: 'Entity XF', category: 'super' },
    'cheetah': { label: 'Cheetah', category: 'super' },
    'infernus': { label: 'Infernus', category: 'super' },
    'vacca': { label: 'Vacca', category: 'super' },
    'bullet': { label: 'Bullet', category: 'super' },
    'fmj': { label: 'FMJ', category: 'super' },
    'reaper': { label: 'Reaper', category: 'super' },
    'pfister811': { label: '811', category: 'super' },
    'tyrus': { label: 'Tyrus', category: 'super' },
    'prototipo': { label: 'X80 Proto', category: 'super' },
    'sheava': { label: 'ETR1', category: 'super' },
    'italigtb': { label: 'Itali GTB', category: 'super' },
    'nero': { label: 'Nero', category: 'super' },
    'penetrator': { label: 'Penetrator', category: 'super' },
    'tempesta': { label: 'Tempesta', category: 'super' },
};

// Toggle states for buttons
const toggleStates = {};

// === EVENT LISTENERS ===
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.type) {
        case 'openMenu':
            openMenu();
            break;
        case 'closeMenu':
            closeMenu();
            break;
        case 'updatePlayers':
            updatePlayers(data.players);
            break;
        case 'toggleState':
            updateToggleState(data.action, data.enabled);
            break;
        case 'showToast':
            showToast(data.toastType, data.title, data.message);
            break;
        case 'updateAdminGroup':
            document.getElementById('admin-group').textContent = data.group?.toUpperCase() || 'ADMIN';
            break;
    }
});

// === MENU FUNCTIONS ===
function openMenu() {
    menuOpen = true;
    adminMenu.classList.remove('hidden');
    SetNuiFocus(true, true);
    refreshPlayers();
}

function closeMenu() {
    menuOpen = false;
    adminMenu.classList.add('hidden');
    SetNuiFocus(false, false);
    fetch(`https://${GetParentResourceName()}/closeMenu`, { method: 'POST', body: '{}' });
}

// === TOAST NOTIFICATIONS ===
function showToast(type, title, message) {
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    
    const icons = {
        success: '✓',
        error: '✕',
        warning: '⚠',
        info: 'ℹ'
    };
    
    toast.innerHTML = `
        <div class="toast-icon">${icons[type] || 'ℹ'}</div>
        <div class="toast-content">
            <div class="toast-title">${escape(title || type.toUpperCase())}</div>
            <div class="toast-message">${escape(message || '')}</div>
        </div>
    `;
    
    toastContainer.appendChild(toast);
    
    // Auto remove
    setTimeout(() => {
        toast.classList.add('hiding');
        setTimeout(() => toast.remove(), 300);
    }, 4000);
}

// === PLAYER LIST ===
function refreshPlayers() {
    fetch(`https://${GetParentResourceName()}/refreshPlayers`, { method: 'POST', body: '{}' });
}

function updatePlayers(players) {
    currentPlayers = players || [];
    document.getElementById('player-count').textContent = currentPlayers.length;
    
    // Update list
    const list = document.getElementById('players-list');
    list.innerHTML = '';
    
    currentPlayers.forEach(p => {
        const item = document.createElement('div');
        item.className = 'player-item';
        item.dataset.id = p.id;
        item.innerHTML = `
            <span class="player-name">${escape(p.name)}</span>
            <span class="player-id">#${p.id}</span>
        `;
        item.addEventListener('click', () => {
            document.querySelectorAll('.player-item').forEach(i => i.classList.remove('selected'));
            item.classList.add('selected');
            document.getElementById('target-player').value = p.id;
            document.getElementById('give-target').value = p.id;
        });
        list.appendChild(item);
    });
    
    // Update selects
    updatePlayerSelects();
}

function updatePlayerSelects() {
    const options = '<option value="">Select a player...</option>' + 
        currentPlayers.map(p => `<option value="${p.id}">${escape(p.name)} (#${p.id})</option>`).join('');
    
    document.getElementById('target-player').innerHTML = options;
    const giveSelect = document.getElementById('give-target');
    giveSelect.innerHTML = '<option value="">Select a player...</option><option value="self">🎯 YOURSELF</option>' + 
        currentPlayers.map(p => `<option value="${p.id}">${escape(p.name)} (#${p.id})</option>`).join('');
}

// === TABS ===
document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        btn.classList.add('active');
        document.getElementById('tab-' + btn.dataset.tab).classList.add('active');
    });
});

// Close button
document.getElementById('btn-close').addEventListener('click', closeMenu);

// === SELF ACTIONS ===
document.querySelectorAll('#tab-self .action-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const action = btn.dataset.action;
        const isToggle = btn.dataset.toggle === 'true';
        
        fetch(`https://${GetParentResourceName()}/${action}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: '{}'
        }).then(r => r.json()).then(data => {
            if (isToggle && data && typeof data.enabled !== 'undefined') {
                updateToggleState(action, data.enabled);
            }
        });
    });
});

function updateToggleState(action, enabled) {
    const btn = document.querySelector(`[data-action="${action}"]`);
    if (!btn) return;
    
    const status = btn.querySelector('.action-status');
    if (status) {
        status.textContent = enabled ? 'ON' : 'OFF';
        status.classList.toggle('on', enabled);
    }
    toggleStates[action] = enabled;
}

// === PLAYER ACTIONS ===
document.getElementById('btn-refresh').addEventListener('click', () => {
    refreshPlayers();
    showToast('success', 'Refreshed', 'Player list updated');
});

document.querySelectorAll('.btn-action').forEach(btn => {
    btn.addEventListener('click', () => {
        const action = btn.dataset.action;
        const target = document.getElementById('target-player').value;
        
        if (!target) {
            showToast('warning', 'No Target', 'Please select a player first');
            return;
        }
        
        if (action === 'kick' || action === 'ban') {
            showModal(action, target);
        } else if (action === 'slay') {
            showConfirmModal('SLAY PLAYER', 'Are you sure you want to kill this player?', () => {
                sendPlayerAction(action, target);
            });
        } else {
            sendPlayerAction(action, target);
        }
    });
});

function sendPlayerAction(action, targetId) {
    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ targetId: parseInt(targetId) })
    });
}

// === SEARCHABLE ITEM SELECT ===
const itemSearch = document.getElementById('item-search');
const searchResults = document.getElementById('search-results');
const selectedItemEl = document.getElementById('selected-item');

itemSearch.addEventListener('focus', () => {
    searchResults.classList.add('active');
    renderSearchResults('');
});

itemSearch.addEventListener('input', (e) => {
    renderSearchResults(e.target.value);
});

document.addEventListener('click', (e) => {
    if (!e.target.closest('.searchable-select')) {
        searchResults.classList.remove('active');
    }
});

function renderSearchResults(query) {
    const q = query.toLowerCase();
    const items = Object.entries(itemDatabase)
        .filter(([key, data]) => 
            key.toLowerCase().includes(q) || 
            data.label.toLowerCase().includes(q)
        )
        .slice(0, 50); // Limit results
    
    searchResults.innerHTML = '';
    
    if (items.length === 0) {
        searchResults.innerHTML = '<div class="search-item"><span class="search-item-name">No items found</span></div>';
        return;
    }
    
    items.forEach(([key, data]) => {
        const item = document.createElement('div');
        item.className = 'search-item';
        item.innerHTML = `
            <span class="search-item-name">${data.icon} ${escape(data.label)}</span>
            <span class="search-item-category">${data.category}</span>
        `;
        item.addEventListener('click', () => selectItem(key, data));
        searchResults.appendChild(item);
    });
}

function selectItem(key, data) {
    selectedItem = { key, ...data };
    selectedItemEl.innerHTML = `
        <div class="selected-item-content">
            <span style="font-size: 20px;">${data.icon}</span>
            <span class="selected-item-name">${escape(data.label)}</span>
            <button class="selected-item-clear" onclick="clearSelectedItem()">✕</button>
        </div>
    `;
    itemSearch.value = '';
    searchResults.classList.remove('active');
}

window.clearSelectedItem = function() {
    selectedItem = null;
    selectedItemEl.innerHTML = '<span class="no-selection">No item selected</span>';
};

// Category tags
document.querySelectorAll('.tag').forEach(tag => {
    tag.addEventListener('click', () => {
        const cat = tag.dataset.cat;
        document.querySelectorAll('.tag').forEach(t => t.classList.remove('active'));
        tag.classList.add('active');
        
        // Filter items by category
        searchResults.classList.add('active');
        const items = Object.entries(itemDatabase)
            .filter(([key, data]) => data.category === cat)
            .slice(0, 50);
        
        renderItemsList(items);
    });
});

function renderItemsList(items) {
    searchResults.innerHTML = '';
    items.forEach(([key, data]) => {
        const item = document.createElement('div');
        item.className = 'search-item';
        item.innerHTML = `
            <span class="search-item-name">${data.icon} ${escape(data.label)}</span>
            <span class="search-item-category">${data.category}</span>
        `;
        item.addEventListener('click', () => selectItem(key, data));
        searchResults.appendChild(item);
    });
}

// Give button
document.getElementById('btn-give').addEventListener('click', () => {
    const target = document.getElementById('give-target').value;
    const amount = parseInt(document.getElementById('give-amount').value) || 1;
    
    if (!target) {
        showToast('warning', 'No Target', 'Please select a target player');
        return;
    }
    
    if (!selectedItem) {
        showToast('warning', 'No Item', 'Please select an item to give');
        return;
    }
    
    const isWeapon = selectedItem.category === 'weapons';
    const endpoint = isWeapon ? 'giveWeapon' : 'giveItem';
    
    fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
            targetId: target === 'self' ? -1 : parseInt(target),
            item: selectedItem.key,
            count: amount
        })
    }).then(() => {
        showToast('success', 'Item Given', `Gave ${amount}x ${selectedItem.label}`);
    });
});

// === VEHICLES TAB ===
const vehicleSearch = document.getElementById('vehicle-search');
const vehicleResults = document.getElementById('vehicle-results');
let selectedVehicle = null;

vehicleSearch?.addEventListener('focus', () => {
    vehicleResults?.classList.add('active');
    renderVehicleResults('');
});

vehicleSearch?.addEventListener('input', (e) => {
    renderVehicleResults(e.target.value);
});

function renderVehicleResults(query) {
    const q = query.toLowerCase();
    const vehicles = Object.entries(vehicleDatabase)
        .filter(([key, data]) => 
            key.toLowerCase().includes(q) || 
            data.label.toLowerCase().includes(q)
        );
    
    if (!vehicleResults) return;
    vehicleResults.innerHTML = '';
    
    vehicles.forEach(([key, data]) => {
        const item = document.createElement('div');
        item.className = 'search-item';
        item.innerHTML = `
            <span class="search-item-name">${escape(data.label)}</span>
            <span class="search-item-category">${data.category}</span>
        `;
        item.addEventListener('click', () => {
            selectedVehicle = key;
            vehicleSearch.value = data.label;
            vehicleResults.classList.remove('active');
        });
        vehicleResults.appendChild(item);
    });
}

// Vehicle buttons
document.querySelectorAll('.vehicle-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const model = btn.dataset.model;
        spawnVehicle(model);
    });
});

document.getElementById('btn-spawn-vehicle')?.addEventListener('click', () => {
    const model = vehicleSearch?.value ? selectedVehicle || vehicleSearch.value : null;
    if (model) {
        spawnVehicle(model);
    } else {
        showToast('warning', 'No Vehicle', 'Please select a vehicle');
    }
});

function spawnVehicle(model) {
    fetch(`https://${GetParentResourceName()}/spawnVehicle`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model: model })
    }).then(() => {
        showToast('success', 'Vehicle Spawned', `Spawned ${model}`);
    });
}

// === MODAL ===
function showModal(action, target) {
    currentAction = { action, target };
    const title = action === 'kick' ? 'KICK PLAYER' : 'BAN PLAYER';
    const message = action === 'kick' 
        ? 'Enter a reason for kicking this player:' 
        : 'Enter a reason and duration for banning this player:';
    
    document.getElementById('modal-title').textContent = title;
    document.getElementById('modal-message').textContent = message;
    document.getElementById('modal-input').value = '';
    document.getElementById('modal-duration').value = '';
    document.getElementById('modal-duration').style.display = action === 'ban' ? 'block' : 'none';
    
    modal.classList.remove('hidden');
}

function showConfirmModal(title, message, onConfirm) {
    document.getElementById('modal-title').textContent = title;
    document.getElementById('modal-message').textContent = message;
    document.getElementById('modal-input').style.display = 'none';
    document.getElementById('modal-duration').style.display = 'none';
    
    modal.classList.remove('hidden');
    
    const confirmBtn = document.getElementById('modal-confirm');
    const oldOnclick = confirmBtn.onclick;
    confirmBtn.onclick = () => {
        modal.classList.add('hidden');
        onConfirm();
        confirmBtn.onclick = oldOnclick;
    };
}

document.getElementById('modal-close').addEventListener('click', () => {
    modal.classList.add('hidden');
    currentAction = null;
});

document.getElementById('modal-cancel').addEventListener('click', () => {
    modal.classList.add('hidden');
    currentAction = null;
});

document.getElementById('modal-confirm').addEventListener('click', () => {
    if (!currentAction) return;
    
    const reason = document.getElementById('modal-input').value || 'No reason provided';
    const duration = parseInt(document.getElementById('modal-duration').value) || 0;
    
    fetch(`https://${GetParentResourceName()}/${currentAction.action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            targetId: parseInt(currentAction.target),
            reason: reason,
            duration: duration
        })
    });
    
    modal.classList.add('hidden');
    showToast('success', currentAction.action.toUpperCase(), `Player ${currentAction.action}ed successfully`);
    currentAction = null;
});

// === HELPERS ===
function GetParentResourceName() {
    const m = window.location.pathname.match(/\/([^/]+)\/html/);
    return m ? m[1] : 'kw_admin';
}

function SetNuiFocus(hasFocus, hasCursor) {
    fetch(`https://${GetParentResourceName()}/setFocus`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ hasFocus, hasCursor })
    });
}

function escape(text) {
    if (!text) return '';
    const d = document.createElement('div');
    d.textContent = text;
    return d.innerHTML;
}

// === INIT ===
console.log('[^1DTF Admin^7] NUI loaded with enhanced features');
