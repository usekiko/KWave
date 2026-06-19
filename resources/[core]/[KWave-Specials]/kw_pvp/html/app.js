// DTF PvP - NUI Controller

const menu = document.getElementById('menu');
const toggleIndicator = document.getElementById('toggle-indicator');
const closeBtn = document.getElementById('close-btn');
const toggleBtn = document.getElementById('toggle-btn');
const statusBadge = document.getElementById('status-badge');

let isEnabled = false;
let isMenuOpen = false;

// Helper for Lua communication
function GetParentResourceName() {
    const path = window.location.pathname;
    const match = path.match(/\/([^/]+)\/html/);
    return match ? match[1] : 'kw_pvp';
}

// Update UI based on state
function updateUI() {
    if (isEnabled) {
        // Enabled state
        statusBadge.textContent = 'ENABLED';
        statusBadge.classList.remove('disabled');
        statusBadge.classList.add('enabled');
        
        toggleBtn.classList.remove('disabled');
        toggleBtn.classList.add('enabled');
        toggleBtn.innerHTML = '<span class="btn-icon">⏻</span><span class="btn-text">DISABLE PvP MODE</span>';
        
        // Show indicator
        toggleIndicator.classList.remove('hidden');
    } else {
        // Disabled state
        statusBadge.textContent = 'DISABLED';
        statusBadge.classList.remove('enabled');
        statusBadge.classList.add('disabled');
        
        toggleBtn.classList.remove('enabled');
        toggleBtn.classList.add('disabled');
        toggleBtn.innerHTML = '<span class="btn-icon">⚡</span><span class="btn-text">ENABLE PvP MODE</span>';
        
        // Hide indicator
        toggleIndicator.classList.add('hidden');
    }
}

// Open menu
function openMenu() {
    isMenuOpen = true;
    menu.classList.remove('hidden');
    updateUI();
}

// Close menu
function closeMenu() {
    isMenuOpen = false;
    menu.classList.add('hidden');
    
    // Tell Lua to release focus
    fetch(`https://${GetParentResourceName()}/closeMenu`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// Toggle PvP mode
function togglePvP() {
    fetch(`https://${GetParentResourceName()}/togglePvP`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    })
    .then(resp => resp.json())
    .then(data => {
        isEnabled = data.enabled;
        updateUI();
    });
}

// Listen for messages from Lua
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.type) {
        case 'openMenu':
            isEnabled = data.enabled;
            openMenu();
            break;
            
        case 'toggle':
            isEnabled = data.enabled;
            updateUI();
            break;
            
        case 'hitmarker':
            let audio = new Audio('headshot.mp3');
            audio.volume = 0.7; // User requested 60%+
            audio.play();
            break;
    }
});

// Event listeners
closeBtn.addEventListener('click', closeMenu);

toggleBtn.addEventListener('click', togglePvP);

toggleIndicator.addEventListener('click', () => {
    togglePvP();
});

// Close on Escape key
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape' && isMenuOpen) {
        closeMenu();
    }
});

// Initial state
menu.classList.add('hidden');
toggleIndicator.classList.add('hidden');

console.log('[^3DTF PvP^7] NUI loaded');
