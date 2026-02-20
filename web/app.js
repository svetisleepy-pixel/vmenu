const app = document.getElementById('app');
const tabs = [...document.querySelectorAll('.tab')];
const panels = [...document.querySelectorAll('.panel')];
const closeBtn = document.getElementById('closeBtn');

let state = {
  dashboard: { onlinePlayers: 0, openReports: 0, activeServices: 0, recentLogs: [] },
  players: [],
  reports: [],
  services: [],
  logs: [],
  quickActions: []
};

const post = async (route, data = {}) => {
  await fetch(`https://${GetParentResourceName()}/${route}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  });
};

function escapeHtml(str) {
  return String(str || '').replace(/[&<>"']/g, (m) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;' }[m]));
}

function switchTab(name) {
  tabs.forEach((tab) => tab.classList.toggle('active', tab.dataset.tab === name));
  panels.forEach((panel) => panel.classList.toggle('active', panel.id === name));
}

function bindTabEvents() {
  tabs.forEach((tab) => tab.addEventListener('click', () => switchTab(tab.dataset.tab)));
  closeBtn.addEventListener('click', () => post('close'));
}

function renderDashboard() {
  const el = document.getElementById('dashboard');
  el.innerHTML = `
    <div class="grid">
      <div class="card"><h3>Online players</h3><p>${state.dashboard.onlinePlayers || 0}</p></div>
      <div class="card"><h3>Open reports</h3><p>${state.dashboard.openReports || 0}</p></div>
      <div class="card"><h3>Active services</h3><p>${state.dashboard.activeServices || 0}</p></div>
      <div class="card"><h3>Total logs</h3><p>${state.logs.length}</p></div>
    </div>
    <h3>Quick announcement</h3>
    <div class="form">
      <textarea id="announcementText" rows="3" placeholder="Write announcement..."></textarea>
      <button id="announceBtn">Send announcement</button>
    </div>
  `;

  document.getElementById('announceBtn').addEventListener('click', () => {
    const message = document.getElementById('announcementText').value;
    post('action', { action: 'announcement', message });
  });
}

function renderPlayers() {
  const el = document.getElementById('players');
  const rows = state.players.map((p) => `
    <tr>
      <td>${p.id}</td>
      <td>${escapeHtml(p.name)}</td>
      <td>${escapeHtml(p.group)}</td>
      <td>${p.warns}</td>
      <td>${p.ping}</td>
      <td>
        <div class="row-actions">
          <button data-action="kick" data-id="${p.id}">Kick</button>
          <button data-action="ban" data-id="${p.id}">Ban</button>
          <button data-action="warn" data-id="${p.id}">Warn</button>
          <button data-action="goto" data-id="${p.id}">Goto</button>
          <button data-action="bring" data-id="${p.id}">Bring</button>
          <button data-action="freeze" data-id="${p.id}">Freeze</button>
          <button data-action="revive" data-id="${p.id}">Revive</button>
          <button data-action="heal" data-id="${p.id}">Heal</button>
          <button data-action="slay" data-id="${p.id}">Slay</button>
        </div>
      </td>
    </tr>
  `).join('');

  el.innerHTML = `
    <div class="form">
      <input id="moderationReason" placeholder="Reason for moderation actions" />
      <input id="serviceTarget" type="number" placeholder="Service target id" />
      <input id="serviceMinutes" type="number" placeholder="Service minutes" />
      <button id="assignService">Assign community service</button>
    </div>
    <table class="table">
      <thead><tr><th>ID</th><th>Name</th><th>Group</th><th>Warns</th><th>Ping</th><th>Actions</th></tr></thead>
      <tbody>${rows}</tbody>
    </table>
  `;

  el.querySelectorAll('button[data-action]').forEach((btn) => {
    btn.addEventListener('click', () => {
      const reason = document.getElementById('moderationReason')?.value || 'No reason';
      post('action', { action: btn.dataset.action, target: Number(btn.dataset.id), reason });
    });
  });

  document.getElementById('assignService').addEventListener('click', () => {
    post('action', {
      action: 'service',
      target: Number(document.getElementById('serviceTarget').value),
      minutes: Number(document.getElementById('serviceMinutes').value),
      reason: document.getElementById('moderationReason').value || 'Service assignment'
    });
  });
}

function renderReports() {
  const el = document.getElementById('reports');
  const reportItems = state.reports.map((r) => `
    <div class="card">
      <h3>#${r.id} | ${escapeHtml(r.category)} | ${escapeHtml(r.status)}</h3>
      <p style="font-size:14px;font-weight:500">${escapeHtml(r.authorName)}: ${escapeHtml(r.message)}</p>
      <div class="row-actions" style="margin-top:8px">
        <button data-claim="${r.id}">Claim</button>
        <button data-close="${r.id}">Close</button>
      </div>
    </div>
  `).join('');

  el.innerHTML = `
    <div class="form">
      <select id="reportCategory">
        <option>General</option>
        <option>Cheating</option>
        <option>RDM/VDM</option>
        <option>Bug</option>
      </select>
      <textarea id="reportMessage" rows="3" placeholder="Create report from panel..."></textarea>
      <button id="createReport">Create report</button>
      <input id="closeReason" placeholder="Reason when closing report" />
    </div>
    <div style="display:grid;gap:10px">${reportItems || '<small>No reports.</small>'}</div>
  `;

  document.getElementById('createReport').addEventListener('click', () => {
    post('action', {
      action: 'createReport',
      category: document.getElementById('reportCategory').value,
      message: document.getElementById('reportMessage').value
    });
  });

  el.querySelectorAll('button[data-claim]').forEach((btn) => btn.addEventListener('click', () => {
    post('action', { action: 'claimReport', reportId: Number(btn.dataset.claim) });
  }));

  el.querySelectorAll('button[data-close]').forEach((btn) => btn.addEventListener('click', () => {
    post('action', {
      action: 'closeReport',
      reportId: Number(btn.dataset.close),
      reason: document.getElementById('closeReason').value || 'Handled'
    });
  }));
}

function renderServices() {
  const el = document.getElementById('services');
  const rows = state.services.map((s) => `
    <tr>
      <td>${s.id}</td>
      <td>${escapeHtml(s.name)}</td>
      <td>${escapeHtml(s.reason)}</td>
      <td>${s.remaining}</td>
      <td><button data-clear="${s.id}">Clear</button></td>
    </tr>
  `).join('');

  el.innerHTML = `
    <table class="table">
      <thead><tr><th>ID</th><th>Name</th><th>Reason</th><th>Minutes left</th><th>Action</th></tr></thead>
      <tbody>${rows || '<tr><td colspan="5">No active community service.</td></tr>'}</tbody>
    </table>
  `;

  el.querySelectorAll('button[data-clear]').forEach((btn) => btn.addEventListener('click', () => {
    post('action', { action: 'clearService', target: Number(btn.dataset.clear) });
  }));
}

function renderLogs() {
  const el = document.getElementById('logs');
  const items = [...state.logs].reverse().map((log) => `
    <div class="log-item">
      <b>${escapeHtml(log.kind)}</b> - ${escapeHtml(log.adminName)}
      ${log.targetName ? `→ ${escapeHtml(log.targetName)}` : ''}
      <div>${escapeHtml(log.message || '')}</div>
      <small>${new Date((log.createdAt || 0) * 1000).toLocaleString()}</small>
    </div>
  `).join('');

  el.innerHTML = `<h3>Admin action logs</h3>${items || '<small>No logs yet.</small>'}`;
}

function render() {
  renderDashboard();
  renderPlayers();
  renderReports();
  renderServices();
  renderLogs();
}

window.addEventListener('message', (event) => {
  const data = event.data;
  if (!data || !data.type) return;

  if (data.type === 'visibility') {
    app.classList.toggle('hidden', !data.visible);
    if (data.payload) {
      state = { ...state, ...data.payload };
      render();
      switchTab('dashboard');
    }
  } else if (data.type === 'sync') {
    state = { ...state, ...data.payload };
    render();
  } else if (data.type === 'logPush') {
    state.logs = [...(state.logs || []), data.entry];
    renderLogs();
  } else if (data.type === 'service') {
    let banner = document.getElementById('serviceBanner');
    if (!banner) {
      banner = document.createElement('div');
      banner.id = 'serviceBanner';
      banner.className = 'service-banner';
      document.body.appendChild(banner);
    }
    banner.textContent = `Community service: ${data.payload.remaining} min remaining (${data.payload.reason})`;
  }
});

bindTabEvents();
setInterval(() => post('action', { action: 'refresh' }), 5000);
