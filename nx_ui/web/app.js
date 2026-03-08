const el = {
  hud: document.querySelector('#hud'),
  target: document.querySelector('#target'),
  targetIcon: document.querySelector('#targetIcon'),
  targetLabel: document.querySelector('#targetLabel'),
  notifications: document.querySelector('#notifications'),
  progress: document.querySelector('#progress'),
  progressLabel: document.querySelector('#progressLabel'),
  progressFill: document.querySelector('#progressFill'),
  inventory: document.querySelector('#inventory'),
  inventoryItems: document.querySelector('#inventoryItems'),
  money: document.querySelector('#money'),
  job: document.querySelector('#job'),
  dispatchList: document.querySelector('#dispatchList')
};

const ringColors = { health: '#ff5f7d', armor: '#70b6ff', stamina: '#49d17d' };
const rings = [...document.querySelectorAll('.ring')];

function setRing(key, value) {
  const ring = rings.find((node) => node.dataset.key === key);
  if (!ring) return;
  const val = Math.max(0, Math.min(100, Number(value || 0)));
  ring.style.background = `conic-gradient(${ringColors[key] || '#4fd1ff'} ${val}%, rgba(255,255,255,0.08) 0)`;
  ring.querySelector('span').textContent = Math.floor(val);
}

function pushNotice({ type = 'info', title = 'Notice', message = '', duration = 3000 }) {
  const item = document.createElement('div');
  item.className = `notice glass ${type}`;
  item.innerHTML = `<h4>${title}</h4><p>${message}</p>`;
  el.notifications.appendChild(item);
  setTimeout(() => item.remove(), duration);
}

function showProgress({ label, duration }) {
  el.progress.classList.remove('hidden');
  el.progressLabel.textContent = label;
  el.progressFill.style.transitionDuration = `${duration}ms`;
  requestAnimationFrame(() => { el.progressFill.style.width = '100%'; });
  setTimeout(() => {
    el.progress.classList.add('hidden');
    el.progressFill.style.transitionDuration = '0ms';
    el.progressFill.style.width = '0%';
  }, duration + 60);
}

function setInventory(items = []) {
  el.inventoryItems.innerHTML = '';
  for (const item of items) {
    const node = document.createElement('button');
    node.className = 'item';
    node.innerHTML = `<div>${item.label}</div><small>x${item.count}</small>`;
    node.addEventListener('click', () => {
      fetch(`https://${GetParentResourceName()}/inventory:useItem`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ name: item.name })
      });
    });
    el.inventoryItems.appendChild(node);
  }
}

window.addEventListener('message', ({ data }) => {
  if (!data || !data.action) return;

  switch (data.action) {
    case 'notify:push':
      pushNotice(data.payload);
      break;
    case 'progress:start':
      showProgress(data.payload);
      break;
    case 'hud:update': {
      setRing('health', data.data.health);
      setRing('armor', data.data.armor);
      setRing('stamina', data.data.stamina);
      el.money.textContent = `$${Number(data.data.money || 0).toLocaleString()}`;
      el.job.textContent = data.data.job || 'Unemployed';
      break;
    }
    case 'target:update':
      el.target.classList.toggle('hidden', !data.visible);
      if (data.icon) el.targetIcon.className = data.icon;
      if (data.label) el.targetLabel.textContent = data.label;
      break;
    case 'inventory:visibility':
      el.inventory.classList.toggle('hidden', !data.visible);
      break;
    case 'inventory:setItems':
      setInventory(data.items);
      break;
    case 'dispatch:update':
      el.dispatchList.innerHTML = '';
      for (const call of (data.calls || []).slice().reverse()) {
        const node = document.createElement('div');
        node.className = 'call';
        node.innerHTML = `<strong>${call.code} • ${call.title}</strong><p>${call.description}</p>`;
        el.dispatchList.appendChild(node);
      }
      break;
    default:
      break;
  }
});

document.querySelector('#closeInventory').addEventListener('click', () => {
  fetch(`https://${GetParentResourceName()}/inventory:close`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}'
  });
});
