<!-- Static developer info — NasTech -->

<section class="about-developer">
  <h2>Who Are We?</h2>
  <p class="about-subtitle">
    NasTech — building open-source tools that people actually use. NasBeat is free, ad-free, and always will be.
  </p>
  <div class="contact-buttons">
    <a href="https://x.com/nastechai" class="contact-btn x" target="_blank" rel="noopener noreferrer" aria-label="NasTech on X" title="X — nastechai">
      <i class="fa-brands fa-x-twitter"></i>
      X
    </a>
    <a href="https://www.linkedin.com/in/naswif-cohen-nsamba-852b3b16a" class="contact-btn linkedin" target="_blank" rel="noopener noreferrer" aria-label="NasTech on LinkedIn" title="LinkedIn">
      <i class="fa-brands fa-linkedin"></i>
      LinkedIn
    </a>
    <a href="https://github.com/nastech-ai" class="contact-btn github" target="_blank" rel="noopener noreferrer" aria-label="NasTech on GitHub" title="GitHub — nastech-ai">
      <i class="fa-brands fa-github"></i>
      GitHub
    </a>
    <a href="mailto:nastechplatforms@gmail.com" class="contact-btn email" aria-label="Email NasTech" title="Email NasTech">
      <i class="fa-solid fa-envelope"></i>
      Email
    </a>
    <!-- Instagram hidden from display per request but kept in markup -->
    <a href="https://instagram.com/nastechaim" class="contact-btn instagram" target="_blank" rel="noopener noreferrer" aria-label="NasTech on Instagram" title="Instagram — nastechaim" style="display:none" aria-hidden="true" tabindex="-1">
      <i class="fa-brands fa-instagram"></i>
      Instagram
    </a>
  </div>
</section>

<style>
  .about-developer {
    text-align: center;
    padding: 0.6rem 1rem;
    background: transparent;
    color: rgba(255, 255, 255, 0.95);
    backdrop-filter: none;
    border-radius: 0;
    margin: 6px 10px;
  }

  .about-developer h2 {
    font-size: 2.5rem;
    font-weight: 700;
    background: linear-gradient(45deg, #ff8a00, #e52e71);
    background-clip: text;
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    margin-top: 0.2rem;
    margin-bottom: 0.6rem;
  }

  .about-subtitle {
    font-family: 'IBM Plex Sans', sans-serif;
    font-weight: 500;
    font-size: 1.2rem;
    margin-top: 0.1rem;
    margin-bottom: 1.5rem;
    max-width: 700px;
    letter-spacing: 0.3px;
    line-height: 1.4;
    padding-top: 0.6rem;
    text-align: center;
    margin-left: auto;
    margin-right: auto;
    background: linear-gradient(45deg, #ff5258, #ffd48e);
    background-clip: text;
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
  }

  .contact-buttons {
    display: flex;
    justify-content: center;
    gap: 1rem;
    flex-wrap: wrap;
  }

  .contact-btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 0.6rem;
    padding: 0.7rem 1.4rem;
    border-radius: 12px;
    text-decoration: none;
    font-weight: 500;
    font-size: 0.9rem;
    transition: transform 0.3s ease, box-shadow 0.3s ease;
    backdrop-filter: blur(10px);
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    line-height: 1;
    color: white;
  }

  .contact-btn i { font-size: 1.2rem; }

  .contact-btn:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 16px rgba(255, 255, 255, 0.4);
    animation: softBlink 1s ease-in-out 3;
  }

  .contact-btn.email {
    background: rgba(255, 255, 255, 0.2);
    border: 1px solid rgba(255, 255, 255, 0.3);
  }

  .contact-btn.linkedin {
    background: #0077b5;
    border: 1px solid rgba(255, 255, 255, 0.3);
  }

  .contact-btn.github {
    background: #333;
    border: 1px solid rgba(255, 255, 255, 0.3);
  }

  .contact-btn.x {
    background: #000;
    border: 1px solid rgba(255, 255, 255, 0.3);
  }

  @keyframes softBlink {
    0%, 100% { filter: brightness(1); transform: scale(1); }
    50% { filter: brightness(1.1); transform: scale(1.02); }
  }

  @media (max-width: 768px) {
    .about-developer { padding: 0.8rem 0.8rem; }
    .about-developer h2 { font-size: 2rem; }
    .about-subtitle { font-size: 0.9rem; }
    .contact-btn { padding: 0.6rem 1rem; font-size: 0.85rem; }
  }
</style>
