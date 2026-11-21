"""
Simulation study for "Knowing People Without Making Them".

Three simulations illustrate the paper's formal results under stated
assumptions. They are not empirical evidence about the real world.

  S1  Closure ratchet: engagement-greedy vs mirror vs goal-targeted
      recommenders acting on drifting user preferences.
  S2  Data capture: probability that an equally needy group is served
      under threshold allocation, as a function of its data size.
  S3  Experiential residual and experiential distance in a synthetic
      population.

Run:  python simulations.py      (writes figures/ and results.txt)
"""
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from scipy.stats import norm
from pathlib import Path

rng = np.random.default_rng(2026)
OUT = Path(__file__).parent
FIG = OUT / "figures"
FIG.mkdir(exist_ok=True)
lines = []

plt.rcParams.update({
    "font.family": "serif", "font.size": 9, "axes.spines.top": False,
    "axes.spines.right": False, "axes.titlesize": 9, "legend.frameon": False,
})
C = {"greedy": "#b5432f", "mirror": "#7a7a7a", "aligned": "#2b6cb0"}


def entropy(p):
    p = np.clip(p, 1e-12, 1)
    return -(p * np.log2(p)).sum(axis=-1)


# ---------------------------------------------------------------- S1
def s1(N=500, K=10, T=300, eta=0.03, eps=0.5, target=0.40, n_goal=2):
    p0 = rng.dirichlet(np.ones(K) * 1.5, size=N)
    # goal items: two items the person says serve their long-run goals
    goals = np.array([rng.choice(K, n_goal, replace=False) for _ in range(N)])
    G = np.zeros((N, K)); np.put_along_axis(G, goals, 1.0, axis=1)
    uG = G / n_goal

    res = {}
    for pol in ["greedy", "mirror", "aligned"]:
        p = p0.copy()
        H, acc, gshare = [], [], []
        for t in range(T + 1):
            H.append(entropy(p).mean())
            acc.append(p.max(axis=1).mean())
            gshare.append((p * G).sum(axis=1).mean())
            if pol == "greedy":
                r = np.zeros_like(p); r[np.arange(N), p.argmax(1)] = 1.0
            elif pol == "mirror":
                r = p
            else:  # steer toward person-authored goals only until target reached
                below = ((p * G).sum(1) < target)[:, None]
                r = np.where(below, (1 - eps) * p + eps * uG, p)
            p = (1 - eta) * p + eta * r
        kl = (np.clip(p,1e-12,1) * np.log2(np.clip(p,1e-12,1) / np.clip(p0,1e-12,1))).sum(1).mean()
        res[pol] = dict(H=np.array(H), acc=np.array(acc), g=np.array(gshare), kl=kl)
    H0 = res["mirror"]["H"][0]
    for pol in res:
        lines.append(f"S1 {pol:8s}: entropy {res[pol]['H'][0]:.3f}->{res[pol]['H'][-1]:.3f} bits; "
                     f"manufactured (entropy removed) {H0 - res[pol]['H'][-1]:.3f} bits; "
                     f"Bayes accuracy {res[pol]['acc'][0]:.3f}->{res[pol]['acc'][-1]:.3f}; "
                     f"goal share {res[pol]['g'][0]:.3f}->{res[pol]['g'][-1]:.3f}; "
                     f"preference shift KL(p_T||p_0) {res[pol]['kl']:.3f} bits")

    fig, ax = plt.subplots(1, 3, figsize=(7.2, 2.3))
    lab = {"greedy": "Engagement-greedy", "mirror": "Mirror (no steering)",
           "aligned": "Goal-targeted, budgeted"}
    t = np.arange(T + 1)
    for pol in ["greedy", "mirror", "aligned"]:
        ax[0].plot(t, res[pol]["acc"], color=C[pol], lw=1.6, label=lab[pol])
        ax[1].plot(t, H0 - res[pol]["H"], color=C[pol], lw=1.6)
        ax[2].plot(t, res[pol]["g"], color=C[pol], lw=1.6)
    ax[0].set_title("(a) Predictability")
    ax[1].set_title("(b) Entropy removed (bits)")
    ax[2].set_title("(c) Share of choices on own goals")
    ax[2].axhline(target, ls=":", lw=0.8, color="k")
    ax[2].text(T, target + 0.015, "person's target", ha="right", fontsize=7)
    for a in ax: a.set_xlabel("Interaction rounds")
    ax[0].set_ylim(0, 1.02); ax[2].set_ylim(0, 0.6)
    fig.legend(*ax[0].get_legend_handles_labels(), loc="lower center", ncol=3,
               bbox_to_anchor=(0.5, -0.06))
    fig.tight_layout(rect=(0, 0.07, 1, 1))
    fig.savefig(FIG / "s1_closure_ratchet.pdf", bbox_inches="tight")
    plt.close(fig)


# ---------------------------------------------------------------- S2
def s2(mu=0.0, tau=1.0, sigma=5.0, c=0.5, theta=1.0, reps=20000):
    ns = np.unique(np.round(np.logspace(0, np.log10(400), 40)).astype(int))
    lam = ns * tau**2 / (ns * tau**2 + sigma**2)
    mean_est = lam * theta + (1 - lam) * mu
    sd_est = lam * sigma / np.sqrt(ns)
    p_served = norm.sf((c - mean_est) / sd_est)
    # Monte Carlo check of the closed form
    mc = []
    for n, l in zip(ns, lam):
        ybar = theta + sigma / np.sqrt(n) * rng.standard_normal(reps)
        mc.append(((l * ybar + (1 - l) * mu) > c).mean())
    mc = np.array(mc)
    rho = (c - mu) / (theta - mu)
    nstar = sigma**2 * rho / (tau**2 * (1 - rho))
    lines.append(f"S2 legibility threshold n* = {nstar:.1f}; max |MC - closed form| = {np.abs(mc - p_served).max():.4f}")
    for n in [5, 10, 25, 50, 100, 400]:
        i = np.argmin(np.abs(ns - n))
        lines.append(f"S2 n={ns[i]:4d}: P(served)={p_served[i]:.3f}, E[estimate]={mean_est[i]:.3f} (true need {theta})")

    fig, ax = plt.subplots(1, 2, figsize=(7.2, 2.4))
    ax[0].plot(ns, mean_est, color=C["aligned"], lw=1.6, label="Expected estimated need")
    ax[0].axhline(theta, color="k", lw=0.8, ls="--", label="True need")
    ax[0].axhline(c, color=C["greedy"], lw=0.8, ls=":", label="Eligibility cutoff")
    ax[0].axvline(nstar, color="gray", lw=0.8)
    ax[0].text(nstar * 1.08, 0.08, r"$n^\ast$", fontsize=8)
    ax[0].set_xscale("log"); ax[0].set_xlabel("Records for the group ($n_g$)")
    ax[0].set_title("(a) Shrinkage pulls needy groups down"); ax[0].legend(fontsize=7)
    ax[1].plot(ns, p_served, color=C["aligned"], lw=1.6, label="Closed form")
    ax[1].plot(ns, mc, "o", ms=2.2, color="k", label="Monte Carlo")
    ax[1].axvline(nstar, color="gray", lw=0.8)
    ax[1].set_xscale("log"); ax[1].set_ylim(-0.02, 1.02)
    ax[1].set_xlabel("Records for the group ($n_g$)")
    ax[1].set_title("(b) Probability an equally needy group is served")
    ax[1].legend(fontsize=7, loc="lower right")
    fig.tight_layout()
    fig.savefig(FIG / "s2_data_capture.pdf", bbox_inches="tight")
    plt.close(fig)


# ---------------------------------------------------------------- S3
def s3(N=40000, a_minus=0.60, a_plus=0.20):
    inc = rng.integers(0, 5, N)            # income quintile
    grp = rng.integers(0, 3, N)            # abstract social group
    losses = rng.poisson(1.2 + 0.15 * (4 - inc))   # poorer: slightly more losses
    gains = rng.poisson(1.0 + 0.10 * inc)
    eps = rng.normal(0, 1.0, N)
    y = 0.4 * inc - 0.3 * grp - a_minus * losses + a_plus * gains + eps  # risk-taking

    cell = inc * 3 + grp
    cell_mean = np.bincount(cell, y) / np.bincount(cell)
    r_demo = y - cell_mean[cell]
    X = np.column_stack([np.eye(15)[cell], losses, gains])
    beta, *_ = np.linalg.lstsq(X, y, rcond=None)
    r_full = y - X @ beta
    v = y.var()
    R2_demo = 1 - r_demo.var() / v
    R2_full = 1 - r_full.var() / v
    # human residual rho(f; experience): share of demographic residual explained by experience
    Z = np.column_stack([np.ones(N), losses, gains])
    g_, *_ = np.linalg.lstsq(Z, r_demo, rcond=None)
    rho = (Z @ g_).var() / r_demo.var()
    lines.append(f"S3 R2 demographic-only {R2_demo:.3f}; with experience {R2_full:.3f}; "
                 f"human residual rho = {rho:.3f}; recovered a- = {-beta[15]:.3f}, a+ = {beta[16]:.3f}")

    # experiential distance within identical cells
    M = 200000
    i = rng.integers(0, N, M); j = rng.integers(0, N, M)
    same = cell[i] == cell[j]
    i, j = i[same], j[same]
    phi = np.column_stack([losses, gains]).astype(float)
    S = np.cov(phi.T)
    d = phi[i] - phi[j]
    dE = np.sqrt(np.einsum("ij,jk,ik->i", d, np.linalg.inv(S), d))
    dy = np.abs(y[i] - y[j])
    bins = np.quantile(dE, np.linspace(0, 1, 11))
    idx = np.clip(np.digitize(dE, bins[1:-1]), 0, 9)
    bx = np.array([dE[idx == k].mean() for k in range(10)])
    by = np.array([dy[idx == k].mean() for k in range(10)])
    bse = np.array([dy[idx == k].std() / np.sqrt((idx == k).sum()) for k in range(10)])
    slope = np.polyfit(dE, dy, 1)[0]
    lines.append(f"S3 within-cell pairs: {len(dE)}; slope of |dy| on d_E = {slope:.3f}")

    # scar asymmetry: effect of one extra loss vs one extra gain
    fig, ax = plt.subplots(1, 2, figsize=(7.2, 2.4))
    ax[0].bar(["Demographics\nonly", "Demographics\n+ experience"], [R2_demo, R2_full],
              color=[C["mirror"], C["aligned"]], width=0.55)
    for k, val in enumerate([R2_demo, R2_full]):
        ax[0].text(k, val + 0.01, f"{val:.2f}", ha="center", fontsize=8)
    ax[0].set_ylabel(r"$R^2$ (in-sample)"); ax[0].set_ylim(0, max(R2_full, 0.5) + 0.1)
    ax[0].set_title(r"(a) Experience hidden in the residual ($\rho$ = %.2f)" % rho)
    ax[1].errorbar(bx, by, yerr=1.96 * bse, fmt="o-", color=C["aligned"], ms=3, lw=1.3)
    ax[1].set_xlabel(r"Experiential distance $d_E$ (same income and group)")
    ax[1].set_ylabel("Mean |difference in risk-taking|")
    ax[1].set_title("(b) Same demographics, different histories")
    fig.tight_layout()
    fig.savefig(FIG / "s3_experience.pdf", bbox_inches="tight")
    plt.close(fig)


if __name__ == "__main__":
    s1(); s2(); s3()
    (OUT / "results.txt").write_text("\n".join(lines) + "\n")
    print("\n".join(lines))
