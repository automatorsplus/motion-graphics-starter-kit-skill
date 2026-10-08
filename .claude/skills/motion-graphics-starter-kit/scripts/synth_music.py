#!/usr/bin/env python3
"""A music bed made in code, for when there is no fal.ai key. Standard library only.

    python3 synth_music.py --seconds 15 --bpm 120 --out assets/music.wav [--mood bright|dark] [--drop 4]

Kick on every beat, clap on 2 and 4, hats on the off-beats, a bass line and a pad over a four-chord loop,
a riser into the drop bar, and a final hit with a tail on the last downbeat. Bars before --drop are the
intro (pad and hats only). Prints the beat and bar times so the cuts can land on them.

It is a serviceable bed, not a track. Generated music (fal_music.sh) sounds far better.
"""
import argparse, math, random, struct, wave

SR = 44100


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seconds", type=float, required=True)
    ap.add_argument("--bpm", type=float, default=120)
    ap.add_argument("--out", required=True)
    ap.add_argument("--mood", choices=["bright", "dark"], default="bright")
    ap.add_argument("--drop", type=int, default=1, help="bar number (0-based) where the drums come in")
    a = ap.parse_args()

    n = int(a.seconds * SR)
    L = [0.0] * n
    R = [0.0] * n
    beat = 60.0 / a.bpm
    bar = beat * 4
    rnd = random.Random(7)

    root = 45 if a.mood == "bright" else 40  # A2 or E2 (MIDI)
    prog = [[0, 4, 7], [-3, 0, 4], [5, 9, 12], [7, 11, 14]] if a.mood == "bright" else [[0, 3, 7], [-4, 0, 3], [-7, -3, 0], [-2, 2, 5]]
    hz = lambda m: 440.0 * 2 ** ((m - 69) / 12)

    def add(t0, samples, pan=0.0):
        i0 = int(t0 * SR)
        gl, gr = math.cos((pan + 1) * math.pi / 4), math.sin((pan + 1) * math.pi / 4)
        for k, s in enumerate(samples):
            i = i0 + k
            if 0 <= i < n:
                L[i] += s * gl
                R[i] += s * gr

    def kick():
        out, ph = [], 0.0
        for k in range(int(0.35 * SR)):
            t = k / SR
            f = 45 + 110 * math.exp(-t * 30)
            ph += 2 * math.pi * f / SR
            out.append(0.9 * math.sin(ph) * math.exp(-t * 9))
        return out

    def clap():
        return [0.35 * (rnd.random() * 2 - 1) * math.exp(-(k / SR) * 28) for k in range(int(0.2 * SR))]

    def hat():
        prev, out = 0.0, []
        for k in range(int(0.05 * SR)):
            x = rnd.random() * 2 - 1
            out.append(0.12 * (x - prev) * math.exp(-(k / SR) * 80))
            prev = x
        return out

    def tone(f, dur, amp, attack=0.01, decay=3.0, harm=(1.0, 0.5, 0.25)):
        out = []
        for k in range(int(dur * SR)):
            t = k / SR
            env = min(1.0, t / attack) * math.exp(-t * decay)
            out.append(amp * env * sum(h * math.sin(2 * math.pi * f * (j + 1) * t) for j, h in enumerate(harm)))
        return out

    bars = int(math.ceil(a.seconds / bar))
    last_bar_t = (bars - 1) * bar if (bars - 1) * bar < a.seconds - beat else (bars - 2) * bar
    for b in range(bars):
        t_bar = b * bar
        if t_bar >= a.seconds:
            break
        chord = prog[b % 4]
        final = t_bar >= last_bar_t
        # pad: one sustained chord per bar
        for m in chord:
            add(t_bar, tone(hz(root + 12 + m), min(bar, a.seconds - t_bar), 0.05, attack=0.25, decay=0.6, harm=(1, 0.3)), pan=rnd.uniform(-0.4, 0.4))
        if final:
            add(t_bar, kick())
            for m in chord:
                add(t_bar, tone(hz(root + m), min(2.5, a.seconds - t_bar), 0.18, decay=1.6), pan=0)
                add(t_bar, tone(hz(root + 24 + m), min(2.5, a.seconds - t_bar), 0.06, decay=1.2), pan=0)
            break
        for q in range(4):
            t = t_bar + q * beat
            add(t + beat / 2, hat(), pan=0.3)
            if b >= a.drop:
                add(t, kick())
                if q in (1, 3):
                    add(t, clap(), pan=-0.1)
                add(t, tone(hz(root + chord[0]), beat * 0.9, 0.22, decay=5, harm=(1, 0.6, 0.3)))
                add(t + beat / 2, tone(hz(root + 24 + chord[(q + 1) % 3]), beat * 0.4, 0.05, decay=9), pan=rnd.uniform(-0.6, 0.6))
        # riser in the bar before the drop
        if b == a.drop - 1:
            seg = int(bar * SR)
            add(t_bar, [0.15 * (k / seg) ** 2 * (rnd.random() * 2 - 1) for k in range(seg)])

    peak = max(max(abs(x) for x in L), max(abs(x) for x in R)) or 1.0
    g = 0.7 / peak  # plain gain to -3 dBFS sample peak; loudness is set later on the finished film
    with wave.open(a.out, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<hh", int(L[i] * g * 32767), int(R[i] * g * 32767)) for i in range(n)))

    print(f"{a.out}  {a.seconds}s at {a.bpm:g} BPM, beat {beat:.3f}s, bar {bar:.3f}s, drop bar {a.drop}")
    print("bar starts: " + ", ".join(f"{b * bar:.2f}" for b in range(bars) if b * bar < a.seconds))


if __name__ == "__main__":
    main()
