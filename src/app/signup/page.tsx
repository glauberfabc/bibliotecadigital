import AuthForm from "@/components/auth/AuthForm";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import Link from "next/link";

export default function SignupPage() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-background px-4">
      <div className="mx-auto w-full max-w-sm">
        <Card>
          <CardHeader className="text-center">
            <CardTitle className="font-headline text-2xl">Crie uma Conta</CardTitle>
            <CardDescription>
              Junte-se à nossa comunidade e comece sua jornada de leitura.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <AuthForm type="signup" />
          </CardContent>
        </Card>
        <p className="mt-4 text-center text-sm text-muted-foreground">
          Já tem uma conta?{" "}
          <Link href="/login" className="font-semibold text-primary underline-offset-4 hover:underline">
            Entrar
          </Link>
        </p>
      </div>
    </div>
  );
}
