const themeToggle = document.querySelector('.theme-toggle');
const savedTheme = localStorage.getItem('theme');
const backToTopButton = document.querySelector('.back-to-top');
const revealElements = document.querySelectorAll('.reveal');

window.addEventListener('load', function () {
  document.body.classList.add('page-loaded');
});

if (savedTheme === 'dark') {
  document.body.classList.add('dark-mode');
  themeToggle.textContent = '☀';
} else {
  themeToggle.textContent = '☾';
}

themeToggle.addEventListener('click', function () {
  document.body.classList.toggle('dark-mode');

  if (document.body.classList.contains('dark-mode')) {
    themeToggle.textContent = '☀';
    localStorage.setItem('theme', 'dark');
  } else {
    themeToggle.textContent = '☾';
    localStorage.setItem('theme', 'light');
  }
});

window.addEventListener('scroll', function () {
  if (window.scrollY > 400) {
    backToTopButton.classList.add('visible');
  } else {
    backToTopButton.classList.remove('visible');
  }
});

backToTopButton.addEventListener('click', function () {
  window.scrollTo({
    top: 0,
    behavior: 'smooth',
  });
});

const revealObserver = new IntersectionObserver(
  function (entries) {
    entries.forEach(function (entry) {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
      }
    });
  },
  {
    threshold: 0.15,
  }
);

revealElements.forEach(function (element) {
  revealObserver.observe(element);
});

async function loadCtfStats() {
  try {
    const response = await fetch('data/ctf-stats.json');

    if (!response.ok) {
      throw new Error('Impossible de charger les statistiques CTF.');
    }

    const data = await response.json();

    document.querySelector('#ctf-last-update').textContent = data.lastUpdate;

    document.querySelector('#tryhackme-username').textContent =
      `@${data.tryhackme.username}`;

    document.querySelector('#rootme-username').textContent =
      `@${data.rootme.username}`;

    document.querySelector('#hackthebox-username').textContent =
      `@${data.hackthebox.username}`;

    document.querySelector('#tryhackme-rooms').textContent =
      data.tryhackme.rooms;

    document.querySelector('#tryhackme-badges').textContent =
      data.tryhackme.badges;

    document.querySelector('#tryhackme-rank').textContent = data.tryhackme.rank;

    document.querySelector('#tryhackme-profile').href = data.tryhackme.profile;

    document.querySelector('#rootme-points').textContent = data.rootme.points;

    document.querySelector('#rootme-challenges').textContent =
      data.rootme.challenges;

    document.querySelector('#rootme-rank').textContent = data.rootme.rank;

    document.querySelector('#rootme-profile').href = data.rootme.profile;

    document.querySelector('#hackthebox-level').textContent =
      data.hackthebox.level;

    document.querySelector('#hackthebox-xp').textContent = data.hackthebox.xp;

    document.querySelector('#hackthebox-rank').textContent =
      data.hackthebox.rank;

    document.querySelector('#hackthebox-profile').href =
      data.hackthebox.profile;
  } catch (error) {
    console.error(error);
  }
}

loadCtfStats();
